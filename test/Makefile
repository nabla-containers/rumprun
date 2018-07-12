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

syscalltest-rumprun.seccomp:
	x86_64-rumprun-netbsd-gcc -o syscalltest-rumprun syscalltest.c
	rumprun-bake solo5_ukvm_seccomp syscalltest-rumprun.seccomp syscalltest-rumprun

run_hw: helloer-rumprun.bin
	rumprun kvm -g '-nographic -vga none' -i helloer-rumprun.bin

run_ukvm: helloer-rumprun.ukvm
	touch dummy
	./ukvm-bin.vm ./helloer-rumprun.ukvm

run_seccomp: helloer-rumprun.seccomp
	touch dummy
	./ukvm-bin.seccomp ./helloer-rumprun.seccomp

run_syscalltest: syscalltest-rumprun.seccomp
	./ukvm-bin.seccomp ./syscalltest-rumprun.seccomp

failing_timer.seccomp: failing_timer.c
	x86_64-rumprun-netbsd-gcc -o failing_timer failing_timer.c
	rumprun-bake solo5_ukvm_seccomp failing_timer.seccomp failing_timer

run_ukvm_rr: ukvm_rr
	touch dummy
	./ukvm-bin.rr ./helloer-rumprun.bin

run_gdb: helloer-rumprun.seccomp
	touch dummy
	cgdb --ex="b ukvm_elf_load" --ex="r helloer-rumprun.seccomp > /dev/null" --ex="finish" --ex="add-symbol-file helloer-rumprun.seccomp 0x100000" ./ukvm-bin.seccomp

run_gdb_timer: failing_timer.seccomp
	touch dummy
	cgdb --ex="b ukvm_elf_load" --ex="r failing_timer.seccomp" --ex="finish" --ex="add-symbol-file failing_timer.seccomp 0x100000" ./ukvm-bin.seccomp


clean:
	rm -f helloer-rumprun.bin helloer-rumprun dummy helloer-rumprun.ukvm helloer-rumprun.seccomp failing_timer.seccomp failing_timer.ukvm syscalltest-rumprun.seccomp
