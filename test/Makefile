helloer-rumprun.ukvm:
	x86_64-rumprun-netbsd-gcc -o helloer-rumprun helloer.c
	rumprun-bake solo5_ukvm_net helloer-rumprun.ukvm helloer-rumprun

ukvm_rr:
	x86_64-rumprun-netbsd-gcc -o helloer-rumprun helloer.c
	rumprun-bake solo5_ukvm_rr_net helloer-rumprun.bin helloer-rumprun

helloer-rumprun.seccomp:
	x86_64-rumprun-netbsd-gcc -o helloer-rumprun helloer.c
	rumprun-bake solo5_ukvm_seccomp helloer-rumprun.seccomp helloer-rumprun

helloer-rumprun.bin:
	x86_64-rumprun-netbsd-gcc -o helloer-rumprun helloer.c
	rumprun-bake hw_virtio helloer-rumprun.bin helloer-rumprun

run_hw: helloer-rumprun.bin
	rumprun kvm -g '-nographic -vga none' -i helloer-rumprun.bin

run_ukvm: helloer-rumprun.ukvm
	touch dummy
	./ukvm-bin.vm ./helloer-rumprun.ukvm

run_seccomp: helloer-rumprun.seccomp
	touch dummy
	./ukvm-bin.seccomp ./helloer-rumprun.seccomp

run_ukvm_rr: ukvm_rr
	touch dummy
	./ukvm-bin.rr ./helloer-rumprun.bin

run_gdb: solo5
	touch dummy
	gdb -tui --ex="b ukvm_elf_load" --ex="r helloer-rumprun.bin > /dev/null" --ex="finish" --ex="add-symbol-file helloer-rumprun.bin 0x100000" ./ukvm-bin


clean:
	rm -f helloer-rumprun.bin helloer-rumprun dummy helloer-rumprun.ukvm helloer-rumprun.seccomp
