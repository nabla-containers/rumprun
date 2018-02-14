.PHONY: setup
setup:
	sudo bash setup-tests.sh

.PHONY: ukvm
ukvm: setup
	x86_64-rumprun-netbsd-gcc -o tcp-rumprun tcp.c
	rumprun-bake solo5_ukvm_net tcp-rumprun.bin tcp-rumprun

.PHONY: ukvm_rr
ukvm_rr: setup
	x86_64-rumprun-netbsd-gcc -o tcp-rumprun tcp.c
	rumprun-bake solo5_ukvm_rr_net tcp-rumprun.bin tcp-rumprun

.PHONY: hw
hw:
	x86_64-rumprun-netbsd-gcc -o tcp-rumprun tcp.c
	rumprun-bake hw_virtio tcp-rumprun.bin tcp-rumprun

.PHONY: run_hw
run_hw: hw
	rumprun kvm -g '-nographic -vga none' -i \
		-I if,vioif,"-net tap,script=no,ifname=tap100" \
		-W if,inet,static,10.0.0.2/24 \
		-- tcp-rumprun.bin

.PHONY: run_ukvm
run_ukvm: ukvm
	touch dummy
	../ukvm-bin.vm --disk=dummy --net=tap100 tcp-rumprun.bin '{"cmdline":"","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"10.0.0.2","mask":"16"}}'

.PHONY: run_ukvm_rr
run_ukvm_rr: ukvm_rr
	touch dummy
	../ukvm-bin.rr --disk=dummy --net=tap100 tcp-rumprun.bin '{"cmdline":"","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"10.0.0.2","mask":"16"}}'

.PHONY: clean
clean:
	rm -f tcp-rumprun.bin tcp-rumprun dummy
