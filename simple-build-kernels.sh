#!/bin/bash
# Quickly build a small config for several architectures
# v6.15 builds on my MSI in ~1.5 minutes - so it will likely take less than a minute on a more decent machine

: ${archs="aarch64 arm riscv64"}
: ${KV=6.15.0}
: ${KSRC=/tmp/linux-kernel-src}
: ${common_config=$KSRC/config-arm64-virtio--blk-net.config}	# trying to build the same one for all. May work for some architectures, may not
: ${outdir_base=$(readlink -f ../linux-6.15.0-out)}

declare -A ARCHS		# new-comers: this will bite you. e.g.:  ARCH=arm64 CROSS_COMPILE=aarch64... ARCH=riscv CROSS_COMPILE=riscv64-...
declare -A CROSS_COMPILES	# cross toolchains
declare -A CONFIGS 		# config files, for merge-configs
declare -A MORE_CONFIGS		# more config key=values
declare -A OUTDIRS		# output build dir

# less to write but can't necessarily initialize everything in a loop...
init_in_loop() {
	for a in $archs ; do
		ARCHS[$a]=$a
		CROSS_COMPILES[$a]=$a-linux-gnu-
		# MORE_CONFIGS[$a=""] # each will set its own
		OUTDIRS[$a]=$outdir_base/$a/
		CONFIGS[$a]=$KSRC/config-arm64-virtio--blk-net.config
	done

	# Adjustments
	ARCHS[aarch64]=arm64
	ARCHS[riscv64]=riscv

	CROSS_COMPILES[arm]=arm-linux-gnueabi-

}


echo $archs
init_in_loop

type cpufreq_performance &> /dev/null && cpufreq_performance # used specifically on one of my machines to prevent powersave/balanced modes

for a in $archs ; do
	set -x
	set -euo pipefail
	mkdir -p ${OUTDIRS[$a]}
	cp ${CONFIGS[$a]} ${OUTDIRS[$a]}/.config
	ARCH=${ARCHS[$a]} CROSS_COMPILE=${CROSS_COMPILES[$a]} make -C $KSRC O=${OUTDIRS[$a]} olddefconfig
	ARCH=${ARCHS[$a]} CROSS_COMPILE=${CROSS_COMPILES[$a]} make -C $KSRC O=${OUTDIRS[$a]} -j$(nproc)
	set +x
	set +euo pipefail
done
