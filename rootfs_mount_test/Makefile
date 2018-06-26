rootfs-rumprun.seccomp: rootfs.c
	x86_64-rumprun-netbsd-gcc -o rootfs-rumprun rootfs.c
	rumprun-bake solo5_ukvm_seccomp rootfs-rumprun.seccomp rootfs-rumprun

run_seccomp: rootfs-rumprun.seccomp
	genisoimage -o data.iso data
	../ukvm-bin.seccomp --disk=data.iso --net=tap100 rootfs-rumprun.seccomp -- '{"cmdline":"a","env":"a=b","blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/"},"cwd":"/data"}'

run_seccomp2: rootfs-rumprun.seccomp
	dd if=/dev/zero of=data.ext2 count=40960 bs=1024
	genext2fs -B 1024 -b 40960 -d data data.ext2
	../ukvm-bin.seccomp --disk=data.ext2 --net=tap100 rootfs-rumprun.seccomp -- '{"cmdline":"/dev","env":"a=b","blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/"},"cwd":"/data"}'

clean:
	rm -f rootfs-rumprun.seccomp
	rm -f rootfs-rumprun
