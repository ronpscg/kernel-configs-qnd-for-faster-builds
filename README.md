# kernel-configs-qnd-for-faster-builds

## TLDR / self reminder
The repo is basically meant to *very* quickly test some kernel builds, in an ever increasing and bloating kernel world.
Started: linux-6.15.0 , arbitrarily (when demonstrating kexec in meetups in 2025).

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

### config-arm64-virtio--blk-net.config
**Supports: arm64 qemu**
A good fragment to start with, requires more work for arm and riscv64. In arm actually it doesn't require much, but there is a panic that was not trivially resolved.

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

As well as both virtio and hd storage devices (commented out deliberately there)


## Other configs that are known to work well and are 
- vexpress for arm 
- defconfig for riscv
- defconfig for the rest really

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
