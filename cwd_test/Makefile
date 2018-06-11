env-rumprun.seccomp: env.c
	x86_64-rumprun-netbsd-gcc -o env-rumprun env.c
	rumprun-bake solo5_ukvm_seccomp env-rumprun.seccomp env-rumprun

run_seccomp: env-rumprun.seccomp
	genisoimage -o data.iso /data
	../ukvm-bin.seccomp --disk=data.iso --net=tap100 env-rumprun.seccomp -- '{"cmdline":"a","env":"a=b","blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/data"},"cwd":"/data"}'

clean:
	rm -f env-rumprun.seccomp
	rm -f env-rumprun
