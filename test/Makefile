.PHONY: ukvm
ukvm:
	x86_64-rumprun-netbsd-gcc -o helloer-rumprun helloer.c
	rumprun-bake solo5_ukvm_net helloer-rumprun.bin helloer-rumprun

.PHONY: ukvm_rr
ukvm_rr:
	x86_64-rumprun-netbsd-gcc -o helloer-rumprun helloer.c
	rumprun-bake solo5_ukvm_rr_net helloer-rumprun.bin helloer-rumprun


.PHONY: hw
hw:
	x86_64-rumprun-netbsd-gcc -o helloer-rumprun helloer.c
	rumprun-bake hw_virtio helloer-rumprun.bin helloer-rumprun

.PHONY: run_hw
run_hw: hw
	rumprun kvm -g '-nographic -vga none' -i helloer-rumprun.bin

.PHONY: run_ukvm
run_ukvm: ukvm
	touch dummy
	./ukvm-bin.vm ./helloer-rumprun.bin

.PHONY: run_ukvm_rr
run_ukvm_rr: ukvm_rr
	touch dummy
	./ukvm-bin.rr ./helloer-rumprun.bin

.PHONY: run_gdb
run_gdb: solo5
	touch dummy
	gdb -tui --ex="b ukvm_elf_load" --ex="r helloer-rumprun.bin > /dev/null" --ex="finish" --ex="add-symbol-file helloer-rumprun.bin 0x100000" ./ukvm-bin


.PHONY: clean
clean:
	rm -f helloer-rumprun.bin helloer-rumprun dummy
