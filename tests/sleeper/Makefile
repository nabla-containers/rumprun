sleeper-rumprun.ukvm:
	x86_64-rumprun-netbsd-gcc -o sleeper-rumprun sleeper.c
	rumprun-bake solo5_ukvm_net sleeper-rumprun.ukvm sleeper-rumprun

sleeper-rumprun.seccomp:
	x86_64-rumprun-netbsd-gcc -o sleeper-rumprun sleeper.c
	rumprun-bake solo5_ukvm_seccomp sleeper-rumprun.seccomp sleeper-rumprun

run_ukvm: sleeper-rumprun.ukvm
	touch dummy
	./ukvm-bin.vm ./sleeper-rumprun.ukvm

run_seccomp: sleeper-rumprun.seccomp
	touch dummy
	./ukvm-bin.seccomp ./sleeper-rumprun.seccomp

run_gdb: sleeper-rumprun.seccomp
	touch dummy
	cgdb --ex="b ukvm_elf_load" --ex="r sleeper-rumprun.seccomp > /dev/null" --ex="finish" --ex="add-symbol-file sleeper-rumprun.seccomp 0x100000" ./ukvm-bin.seccomp

clean:
	rm -f sleeper-rumprun.bin sleeper-rumprun dummy sleeper-rumprun.ukvm sleeper-rumprun.seccom
