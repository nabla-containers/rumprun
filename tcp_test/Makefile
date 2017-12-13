.PHONY: setup
setup:
	sudo bash setup-tests.sh

.PHONY: solo5
solo5: setup
	x86_64-rumprun-netbsd-gcc -o tcp-rumprun tcp.c
	rumprun-bake solo5_net tcp-rumprun.bin tcp-rumprun

.PHONY: hw
hw:
	x86_64-rumprun-netbsd-gcc -o tcp-rumprun tcp.c
	rumprun-bake hw_virtio tcp-rumprun.bin tcp-rumprun

.PHONY: run_hw
run_hw: hw
	rumprun kvm -g '-nographic -vga none' -i tcp-rumprun.bin {"cmdline":"","net":{"if":"virtionet0","cloner":"True","type":"inet","method":"static","addr":"10.0.0.2","mask":"16"}}

.PHONY: run_ukvm
run_ukvm: solo5
	touch dummy
	time ../ukvm-bin --disk=dummy --net=tap100 tcp-rumprun.bin '{"cmdline":"","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"10.0.0.2","mask":"16"}}' 

.PHONY: clean
clean:
	rm -f tcp-rumprun.bin tcp-rumprun dummy
