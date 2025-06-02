# kernel-configs-qnd-for-faster-builds

## TLDR / self reminder
The repo is basically meant to *very* quickly test some kernel builds, in an ever increasing and bloating kernel world.
Started: *linux-6.15.0* , arbitrarily (when demonstrating kexec in meetups in 2025).

I may put here some narrowed-down configs, as unfortunately the trivial "let's get virtio stuff working for all platforms" is nice in Theory, and somewhat less nice in practice.

Motivation:
- On arm64 the Image would be 9.1MB cf. 23M in a default build
- On risc-v it wouldn't be that big - but a lot of modules are built
- arm images are unnecessarily huge
And so on.

What used to be a less than one minute build on my reference host, became closer to 5 or 10 minutes, and I don't like waiting for things to happen...


### Other related projects to look for more things
Won't write too much about it. This repo exists because the defconfig for all architectures now are bloated. Sometimes we just want to build something to 
test that some things work.
Other relevant repos:
- https://github.com/ronpscg/kernel-configs should do a good work in x86_64 for quite a lot of minimal to full DRM and distro supporting kernels
- Obviously PscgBuildOS and mini-linux


## Some notes about some configs / what's here now

## Networking and build times
**TLDR: if you don't need networking, remove the lines from the config files or build with `ENABLE_NETWORKING=false`**
It's trivial. If you use `ENABLE_NETWORKING=false` it disables everything. You can modify the code to be more specific. The default is to have networking on,
for the minimum functionality of having DHCP working, and working with virtio-net / virtio-net-device (the latter is useful if you do not have `CONFIG_PCI=y`)

We did choose more or less the minimal necessary configs anyhow.
Also: Use `virtio-net-device` and `virtio-net` if you do not have `CONFIG_PCI` (which you don't in the default arm/arm64 config presented here)

An example for size and time differences in ARM:
- ~2MB uncompressed/~1MB compressed
- 1:05 cf. 0:42  (23 seconds)

arm with networking (65 seconds)
```
Mon Jun  2 10:22:24 AM IDT 2025
Mon Jun  2 10:23:29 AM IDT 2025

7.5M    vmlinux
6.3M    arch/arm/boot/Image
3.1M    arch/arm/boot/zImage

```

arm without networking (42 seconds)
```
Mon Jun  2 10:25:23 AM IDT 2025
Mon Jun  2 10:26:05 AM IDT 2025

5.4M    vmlinux
4.6M    arch/arm/boot/Image
2.2M    arch/arm/boot/zImage

```


### config-arm64-virtio--blk-net.config
**Supports: arm64 qemu**
**Supports: arm (with very few config additions)
A good fragment to start with, requires more work for arm and riscv64. In arm actually it doesn't require much, but there is a panic that was not trivially resolved, unless you know a thing or two ( ;-) ) - which is why you can see that the sample script, adds some more configurations to it.

It is a fragment. But it builds well, in about 1.5 minutes frmo a clean state  as per *v6.15.0* with
```
ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make olddefconfig
ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make -j $(nproc)
```

Tested with:
```
NETWORKPARAMS_0="-netdev user,id=net0 -device virtio-net-device,netdev=net0" STORAGEPARAMS_REMOVABLE_0="" STORAGEPARAMS_EMMC_0="" .../pscg_busyboxos-arm64/run-qemu.sh
And also with the STORAGE_PARAMS.

I did not check installation yet because I went on the other architectures, but it should work
```

#### Adding virtio-console
Doable with adding CONFIG_PCI  and CONFIG_VIRTIO_CONSOLE (just as with x86)
```
CMDLINE="console=ttyAMA0  console=hvc0 stopatramdisk" QEMUOPTIONS=" -chardev stdio,id=virtiocon0,mux=on,signal=off   -device virtio-serial-pci   -device virtconsole,chardev=virtiocon0 -mon chardev=virtiocon0,mode=readline  " CONSOLEPARAMS_0=""  /home/ron/shared_artifacts3/runqemus/pscg_busyboxos-arm64/run-qemu.sh --complete-command-line-override
```

As well as both virtio and hd storage devices (commented out deliberately there)

**Also doable without PCI**
```
CMDLINE="console=ttyAMA0 console=hvc0 stopatramdisk" QEMUOPTIONS=" \
  -chardev stdio,id=virtiocon0,mux=on,signal=off \
  -device virtio-serial-device,id=virtioserialbus0 \
  -device virtconsole,chardev=virtiocon0,name=org.qemu.console.builtin.0,bus=virtioserialbus0.0 \
  -mon chardev=virtiocon0,mode=readline \
" CONSOLEPARAMS_0="" /home/ron/shared_artifacts3/runqemus/pscg_busyboxos-arm64/run-qemu.sh --complete-command-line-override
```

## Other configs that are known to work well and are 
- vexpress for arm 
- defconfig for riscv
- defconfig for the rest really


## arm running of virtio
GRAPHICSPARAMS_0="" CMDLINE="console=ttyAMA0 console=hvc0 stopatramdisk earlycon=pl011,0x9000000,115200" QEMUOPTIONS=" \
  -chardev stdio,id=virtiocon0,mux=on,signal=off \
  -device virtio-serial-device,id=virtioserialbus0 \
  -device virtconsole,chardev=virtiocon0,bus=virtioserialbus0.0 \
  -mon chardev=virtiocon0,mode=readline  " CONSOLEPARAMS_0="" /home/ron/shared_artifacts3/runqemus/pscg_busyboxos-arm/run-qemu.sh --complete-command-line-override

We use the same config file for arm64 - and "manually" add `CONFIG_ARCH_VIRT=y` . This results in a boot, that with that config panics.

Sizes for that:
```
$ du -sh vmlinux arch/arm/boot/Image  arch/arm/boot/zImage 
7.4M	vmlinux
6.3M	arch/arm/boot/Image
3.1M	arch/arm/boot/zImage
```


### config=x86_64-virtio--blk-net-console.config

Running example:
```
qemu-system-x86_64 -kernel /home/ron/dev/linux-6.15.0-out/x86_64/arch/x86/boot/bzImage -enable-kvm  \
    -initrd /home/ron/pscgbuildos-builds/target/product/pscg_debos/build-x86_64/image_materials_workdir/installables/bootfat/initramfs.cpio 
    \-append "stopatramdisk earlycon=hvc0 console=tty0 console=hvc0 net.ifnames=0 pscgrd.hw.bsp=qemu" 
    -m 2048  \
    -chardev stdio,id=virtiocon0,mux=on,signal=off  -device virtio-serial-pci   -device virtconsole,chardev=virtiocon0 chardev=virtiocon0,mode=readline
```

Explanation about the commmand line:
* Adding `chardev=virtiocon0,mode=readline` to the QEMU command and add `mux=on` to the `-chardev stdio,id=virtiocon0,signal=off` allows something like `-nographic` 
or `-serial mon:stdio` on that hvc console. `signal=off` prevents Ctrl+C from terminating the instance, and the monitor enables termination via Ctrl A+X.

On x86_64 the HVC is really unnecessary, as (AFAIK) it requires PCI anyhow, but building it like this is still super fast, and it allows to better unify the command lines of other builds,
other than the annoying *virtio-serial-pci* obligation which is not necessasry on other platforms.

**Main Problem here** - earlycon / earlyprintk do not go to HVC , so it's better to use /dev/ttyS0 or /dev/tty0 if using FRAMEBUFFER_CONSOLE





## More QEMU command line options etc.
**WARNING** as I always say in my courses, QEMU params are notoriously changing between versions.

Run QEMU waiting for someone to connect on the hvc0 socket (you can modify `wait=on` to `wait=off` to connect to it after booting
```
qemu-system-x86_64 -kernel /home/ron/dev/linux-6.15.0-out/x86_64/arch/x86/boot/bzImage   -enable-kvm  -initrd /home/ron/pscgbuildos-builds/target/product/pscg_debos/build-x86_64/image_materials_workdir/installables/bootfat/initramfs.cpio -append "stopatramdisk earlyprintk console=tty0 console=hvc0 net.ifnames=0 pscgrd.hw.bsp=qemu" -m 2048   -chardev socket,id=hvc0_socket,path=/tmp/qemu_hvc0.sock,server=on,wait=on -chardev stdio,id=virtiocon0   -device virtio-serial-pci   -device virtconsole,chardev=hvc0_socket
```

From another terminal, connect using `socat` (or an equivalent tool)
```
socat STDIO,raw,echo=0 UNIX-CONNECT:/tmp/qemu_hvc0.sock
```

**So for example, if you want to have**
- ttyS0 as the active console (put it last)
- tty0 on a GUI
- hvc0 connectable via socat (and not waiting for it)

You would do something like:
```
qemu-system-x86_64 -kernel /home/ron/dev/linux-6.15.0-out/x86_64/arch/x86/boot/bzImage   -enable-kvm  \
    -initrd /home/ron/pscgbuildos-builds/target/product/pscg_debos/build-x86_64/image_materials_workdir/installables/bootfat/initramfs.cpio \
    -append "stopatramdisk console=tty0 console=hvc0 console=ttyS0 net.ifnames=0 pscgrd.hw.bsp=qemu" \
    -chardev socket,id=hvc0_socket,path=/tmp/qemu_hvc0.sock,server=on,wait=off -device virtio-serial-pci -device virtconsole,chardev=hvc0_socket \
    -serial mon:stdio
```


I think this should make it clear enough...


# Build time and sizes for that:
```
Kernel: arch/x86/boot/bzImage is ready  (#1)

real	0m48.812s
user	11m55.552s
sys	1m27.454s
Sun Jun  1 03:58:42 PM IDT 2025
Sun Jun  1 03:59:30 PM IDT 2025
```

```
ron@ronmsi:~/dev/linux-6.15.0-out/x86_64$ du -sh vmlinux arch/x86/boot/bzImage 
8.2M	vmlinux
2.1M	arch/x86/boot/bzImage
```


## Definitely missing
ext4


But OK, we'll see about the others later
