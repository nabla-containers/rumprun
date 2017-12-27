.PHONY: solo5
solo5:
	x86_64-rumprun-netbsd-gcc -o helloer-rumprun helloer.c
	rumprun-bake solo5_net helloer-rumprun.bin helloer-rumprun

.PHONY: hw
hw:
	x86_64-rumprun-netbsd-gcc -o helloer-rumprun helloer.c
	rumprun-bake hw_virtio helloer-rumprun.bin helloer-rumprun

.PHONY: run_hw
run_hw: hw
	rumprun kvm -g '-nographic -vga none' -i helloer-rumprun.bin

.PHONY: run_ukvm
run_ukvm: solo5
	touch dummy
	./ukvm-bin ./helloer-rumprun.bin

.PHONY: clean
clean:
	rm -f helloer-rumprun.bin helloer-rumprun dummy
