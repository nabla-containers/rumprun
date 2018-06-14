.PHONY: setup
setup:
	sudo bash setup-tests.sh

test_curl-rumprun.ukvm:
	x86_64-rumprun-netbsd-gcc -o test_curl-rumprun test_curl.c
	rumprun-bake solo5_ukvm_net test_curl-rumprun.ukvm test_curl-rumprun

test_curl.nabla:
	x86_64-rumprun-netbsd-gcc -o test_curl test_curl.c
	rumprun-bake solo5_ukvm_seccomp test_curl.nabla test_curl

.PHONY: ukvm_rr
ukvm_rr: setup
	x86_64-rumprun-netbsd-gcc -o test_curl-rumprun test_curl.c
	rumprun-bake solo5_ukvm_rr_net test_curl-rumprun.bin test_curl-rumprun

.PHONY: hw
hw:
	x86_64-rumprun-netbsd-gcc -o test_curl-rumprun test_curl.c
	rumprun-bake hw_virtio test_curl-rumprun.bin test_curl-rumprun

.PHONY: run_hw
run_hw: hw
	rumprun kvm -g '-nographic -vga none' -i \
		-I if,vioif,"-net tap,script=no,ifname=tap100" \
		-W if,inet,static,10.0.0.2/24 \
		-- test_curl-rumprun.bin

.PHONY: run_ukvm
run_ukvm: test_curl-rumprun.ukvm
	touch dummy
	../ukvm-bin.vm --disk=dummy --net=tap100 test_curl-rumprun.ukvm '{"cmdline":"test_curl 10.0.0.4","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"10.0.0.2","mask":"16"}}'

.PHONY: run_seccomp
run_seccomp: test_curl.nabla
	touch dummy
	../ukvm-bin.seccomp --disk=dummy --net=tap100 test_curl.nabla '{"cmdline":"test_curl 10.0.0.4","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"10.0.0.2","mask":"16"}}'

.PHONY: run_ukvm_rr
run_ukvm_rr: ukvm_rr
	touch dummy
	../ukvm-bin.rr --disk=dummy --net=tap100 test_curl-rumprun.bin '{"cmdline":"","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"10.0.0.2","mask":"16"}}'

.PHONY: clean
clean:
	rm -f test_curl-rumprun.bin test_curl-rumprun test_curl test_curl.nabla dummy test_curl-rumprun.ukvm
