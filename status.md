# Status of the quick and minimal kernel builds at runtime. linux-6.17-rc4

You can test them as per the instructions in the README.md file in essence. I use the *PscgBusyboxOS*.
For your convenience, I write below the commands used to boot. All of the qemu artifacts etc. have been derived from the youtube videos that demonstrated the storage
considerations, so I keep the path identical:

*~/aug19-pscgbuildos/artifacts/runqemus/<arch>/*
where `<arch>` was:
*\
- pscg_busyboxos-arm64
- pscg_busyboxos-arm
- pscg_busyboxos-x86_64
- pscg_busyboxos-i386
- pscg_busyboxos-riscv
- pscg_busyboxos-loongarch
- pscg_busyboxos-s390
*

The status notes below use the *architetcture* name as per the script, which represents the toolchain. It could be changed, it doesn't really matter.

**NOTE that the objective here is not to make everything work or perfect. The most important thing is to ensure that everything BUILDS. Fixing things are often done as optimization exercises in the PSCG Embedded Linux courses**


Also note that the config fragment used was created at *linux-6.15-rc<?>* - and there have been changes that makes previously tested configuration to not work. Some fixes are very easy, some are, not too hard :-)

Example for *arm*:
```
-GENERIC_GETTIMEOFDAY y
-GENERIC_TIME_VSYSCALL y
-GENERIC_VDSO_32 y
-GENERIC_VDSO_DATA_STORE y
-HAVE_GENERIC_VDSO y
-SERIAL_AMBA_PL011_CONSOLE y
-SERIAL_CORE y
-SERIAL_CORE_CONSOLE y
-SERIAL_EARLYCON y
 SERIAL_AMBA_PL011 y -> n
 VDSO y -> n
```
This would yield an hvc working, whereas non-hvc console not, for obvious reasons to those who have some relevant experience. For those who don't - well, now you will. :-)
The interesting thing here, is that IIRC, it was different at 6.17-rc3. I did not look into it, and this can be another nice exercise to explore.


This file will be updated as per the latest tested versions. As the work doesn't really matter, and the essence does and it is reflected in the *README.md* file, the "reference configs" will not be updated as often, or at all. Only the fragment and the build shell script.

## x86_64:
- console: ok
- hvc:  ok
- storage: ok

## i386/i686:
- console: ok
- hvc:  ok
- storage: ok

## aarch64:
- console: ok
- hvc:  ok
- storage: ok

## arm/armhf:
- console: ok (not at 6.17-rc4 - see exercise above)
- hvc:  ok
- storage: ok

Note: while counterintuitive, armhf toolchain also requires the kernel to support VFP

## riscv64
- console:  not ok
- hvc:   not ok
- storage: 

## s390x: 
- console: ok  (console is /dev/ttysclp0)
- hvc:  not ok
- storage: not ok

## loongarch64: boots only with EFI. panics on EFI.
- console: not ok (unless building with 8250 console etc.) - but it panics. That's OK for the minimal build, and is used as a boot fixing exercise.
- hvc:  not ok
- storage: 
