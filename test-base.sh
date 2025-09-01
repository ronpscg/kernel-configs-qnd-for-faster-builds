#!/bin/bash

# Customize it for your need with switch cases etc.

: ${KV=6.17-rc4}
: ${BASE_RUNQEMUDIR=$HOME/aug19-pscgbuildos/artifacts/runqemus}
: ${outdir_base=$(readlink -f ../out-linux-$KV-kernels)}
runqemudir="$BASE_RUNQEMUDIR/pscg_busyboxos-"
KERNEL_IMAGE="$outdir_base/"


# out of brevity, we will not allow customization of most of the params out of the script params here anyway

main() {
	case $1 in
		arm) 
			runqemudir+=arm
			KERNEL_IMAGE+=arm/arch/arm/boot/zImage
			;;
		armhf) 
			runqemudir+=arm
			KERNEL_IMAGE+=armhf/arch/arm/boot/zImage
			;;
		aarch64|arm64) 
			runqemudir+=arm64
			KERNEL_IMAGE+=aarch64/arch/arm64/boot/Image
			;;
		riscv|riscv64) 
			runqemudir+=riscv
			KERNEL_IMAGE+=riscv64/arch/riscv/boot/Image.gz
			;;
		x86_64|amd64) 
			runqemudir+=x86_64 
			KERNEL_IMAGE+=x86_64/arch/x86/boot/bzImage
			;;
		i386|i686) 
			runqemudir+=i386 
			KERNEL_IMAGE+=i686/arch/x86/boot/bzImage
			;;
		loongarch|loongarch64) 
			runqemudir+=loongarch
			KERNEL_IMAGE+=loongarch64/arch/loongarch/boot/vmlinux.efi
			;;
		s390|s390x) 
			runqemudir+=s390
			KERNEL_IMAGE+=s390x/arch/s390/boot/bzImage
			;;
		sparc64)
			runqemudir+=sparc64
			KERNEL_IMAGE+=sparc64/vmlinux
			# This is a case where 
			# qemu-system-sparc64 -kernel vmlinux -nographic -append "console=/dev/ttyS0" will work for you, while runnning zImage and image won't.
			# Can you figure out why?
			;;
		*)
			echo "Please provide a supported architectures in \$1/ You provided: $1"
	esac


	echo $runqemudir
	echo $KERNEL_IMAGE
	echo $BIOSPARAMS

	# You don't necesssarily want to do that (!)
	#CMDLINE="pscgrd.debug.openvts=all " # this behavior will confuse you if you don't know well the system
	CMDLINE="pscgrd.debug.openvts=hvc stopatramdisk=pre_removable"
	[ -n "$KERNEL_IMAGE" ] && export KERNEL_IMAGE
	[ -n "$BIOSPARAMS" ] && export BIOSPARAMS
	[ -n "$CMDLINE" ] && export CMDLINE

	$runqemudir/run-qemu.sh
}

main $@
