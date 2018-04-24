switches-rumprun.ukvm:
	x86_64-rumprun-netbsd-gcc -o switches-rumprun switches.c
	rumprun-bake solo5_ukvm_net switches-rumprun.ukvm switches-rumprun

ukvm_rr:
	x86_64-rumprun-netbsd-gcc -o switches-rumprun switches.c
	rumprun-bake solo5_ukvm_rr_net switches-rumprun.bin switches-rumprun

switches-rumprun.seccomp:
	x86_64-rumprun-netbsd-gcc -o switches-rumprun switches.c
	rumprun-bake solo5_ukvm_seccomp switches-rumprun.seccomp switches-rumprun

switches-rumprun.bin:
	x86_64-rumprun-netbsd-gcc -o switches-rumprun switches.c
	rumprun-bake hw_virtio switches-rumprun.bin switches-rumprun

run_hw: switches-rumprun.bin
	rumprun kvm -g '-nographic -vga none' -i switches-rumprun.bin

run_ukvm: switches-rumprun.ukvm
	touch dummy
	./ukvm-bin.vm --mem=1024 ./switches-rumprun.ukvm

run_seccomp: switches-rumprun.seccomp
	touch dummy
	./ukvm-bin.seccomp ./switches-rumprun.seccomp

failing_timer.seccomp: failing_timer.c
	x86_64-rumprun-netbsd-gcc -o failing_timer failing_timer.c
	rumprun-bake solo5_ukvm_seccomp failing_timer.seccomp failing_timer

run_ukvm_rr: ukvm_rr
	touch dummy
	./ukvm-bin.rr ./switches-rumprun.bin

run_gdb: switches-rumprun.seccomp
	touch dummy
	gdb -tui --ex="b ukvm_elf_load" --ex="r switches-rumprun.seccomp > /dev/null" --ex="finish" --ex="add-symbol-file switches-rumprun.seccomp 0x100000" ./ukvm-bin.seccomp

run_gdb_timer: failing_timer.seccomp
	touch dummy
	gdb -tui --ex="b ukvm_elf_load" --ex="r failing_timer.seccomp > /dev/null" --ex="finish" --ex="add-symbol-file failing_timer.seccomp 0x100000" ./ukvm-bin.seccomp


clean:
	rm -f switches-rumprun.bin switches-rumprun dummy switches-rumprun.ukvm switches-rumprun.seccomp failing_timer.seccomp failing_timer.ukvm
