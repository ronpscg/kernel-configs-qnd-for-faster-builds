#!/bin/bash
# Quickly build a small config for several architectures
# v6.15 builds on my MSI in ~1.5 minutes - so it will likely take less than a minute on a more decent machine

LOCAL_DIR=$(dirname $(readlink -f $0))
: ${archs="aarch64 arm riscv64 x86_64"}
# archs=x86_64
archs=arm
: ${KV=6.15.0}
: ${KSRC=/tmp/linux-kernel-src}
: ${common_config=$LOCAL_DIR/linux-$KV/arm64/config-arm64-virtio--blk-net.config}	# trying to build the same one for all. May work for some architectures, may not
: ${outdir_base=$(readlink -f ../wip-linux-6.15.0-out)}

declare -A ARCHS		# new-comers: this will bite you. e.g.:  ARCH=arm64 CROSS_COMPILE=aarch64... ARCH=riscv CROSS_COMPILE=riscv64-...
declare -A CROSS_COMPILES	# cross toolchains
declare -A CONFIGS 		# config files, for merge-configs
declare -A MORE_CONFIGS		# more config key=values
declare -A OUTDIRS		# output build dir


: ${ENABLE_NETWORKING=true}	# set to false to save some time and space if you do not need networking support

# less to write but can't necessarily initialize everything in a loop...
init_in_loop() {
	for a in $archs ; do
		ARCHS[$a]=$a
		CROSS_COMPILES[$a]=$a-linux-gnu-
		# MORE_CONFIGS[$a=""] # each will set its own
		OUTDIRS[$a]=$outdir_base/$a/
		CONFIGS[$a]=$common_config

		if [ ! "$ENABLE_NETWORKING" = "true" ] ; then
			MORE_CONFIGS[$a]+=" CONFIG_NET=n"
		fi
	done

	# Adjustments
	ARCHS[aarch64]=arm64
	ARCHS[riscv64]=riscv

	#
	# arm
	#
	CROSS_COMPILES[arm]=arm-linux-gnueabi-

	# Needed for virtio console
	MORE_CONFIGS[arm]+=" CONFIG_ARCH_VIRT=y"
	# It is a superb exercise to DEBUG and understand why it is needed, without having the answer ready for you
	# Since the answer is ready for you, you may read:
	# https://linux-arm-kernel.infradead.narkive.com/broMa83B/why-is-floating-point-emulation-necessary
	MORE_CONFIGS[arm]+=" CONFIG_VFP=y" 

}

#
# $1 kernel dst
# $2 list of overrides ( e.g. CONFIG_FOO=y CONFIG_BAR=m CONFIG_BAZ=n )
# $3 arch
#
# I am not sure that ARCH is needed for the config scripts
#
do_config_overrides() {
	local dst=$1
	local list=$2
	local arch=$3
	if [ -z "$list" ] ; then
		return
	fi
	(
	cd $dst
	export ARCH=$arch

	for i in $list ; do
		key=$(echo $i| cut -f1 -d=)
		value=$(echo $i| cut -f2 -d=)
		./source/scripts/config --set-val $key $value || exit 1
	done
	)
}

echo $archs
init_in_loop

type cpufreq_performance &> /dev/null && cpufreq_performance # used specifically on one of my machines to prevent powersave/balanced modes

for a in $archs ; do
	set -x
	set -euo pipefail
	mkdir -p ${OUTDIRS[$a]}
	cp ${CONFIGS[$a]} ${OUTDIRS[$a]}/.config
	do_config_overrides ${OUTDIRS[$a]} "${MORE_CONFIGS[$a]}" $a
	ARCH=${ARCHS[$a]} CROSS_COMPILE=${CROSS_COMPILES[$a]} make -C $KSRC O=${OUTDIRS[$a]} olddefconfig
	start=$(date)
	ARCH=${ARCHS[$a]} CROSS_COMPILE=${CROSS_COMPILES[$a]} time make -C $KSRC O=${OUTDIRS[$a]} -j$(nproc)
	end=$(date)
	echo -e "$start\n$end\n$(du -sh ${OUTDIRS[$a]}/vmlinux)" | tee -a /tmp/buildstats
	set +x
	set +euo pipefail
done
