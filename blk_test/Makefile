.PHONY: setup

blk-rumprun.ukvm: blk.c
	x86_64-rumprun-netbsd-gcc -o blk-rumprun blk.c
	rumprun-bake solo5_ukvm_net blk-rumprun.ukvm blk-rumprun

blk-rumprun.seccomp: blk.c
	x86_64-rumprun-netbsd-gcc -o blk-rumprun blk.c
	rumprun-bake solo5_ukvm_seccomp blk-rumprun.seccomp blk-rumprun

.PHONY: ukvm_rr
ukvm_rr:
	x86_64-rumprun-netbsd-gcc -o blk-rumprun blk.c
	rumprun-bake solo5_ukvm_rr_net blk-rumprun.bin blk-rumprun

.PHONY: hw
hw:
	x86_64-rumprun-netbsd-gcc -o blk-rumprun blk.c
	rumprun-bake hw_virtio blk-rumprun.bin blk-rumprun

.PHONY: run_hw
run_hw: hw
	rumprun kvm -g '-nographic -vga none' -i \
		-I if,vioif,"-net tap,script=no,ifname=tap100" \
		-W if,inet,static,10.0.0.2/24 \
		-- blk-rumprun.bin
test.ext2:
	dd if=/dev/zero of=test.ext2 count=1000 bs=1024
	genext2fs -B 1024 -b 1000 -d test test.ext2
	#mkfs.ext2 test.ext2
	#e2cp test/aaaaaaaaaaaaaaax test.ext2:/.

test.iso: test
	genisoimage -U -J -f -joliet-long -r -allow-lowercase -allow-multidot -o test.iso test

.PHONY: run_ukvm
run_ukvm: blk-rumprun.ukvm test.iso test.ext2
	touch dummy
	#../ukvm-bin.vm --disk=test.iso --net=tap100 blk-rumprun.ukvm '{"cmdline":"","blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/test"}}'
	../ukvm-bin.vm --disk=test.ext2 --net=tap100 blk-rumprun.ukvm '{"cmdline":"","blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/test"}}'
	e2tail test.ext2:/bla

.PHONY: run_seccomp
run_seccomp: blk-rumprun.seccomp test.iso test.ext2
	touch dummy
	../ukvm-bin.seccomp --disk=test.iso --net=tap100 blk-rumprun.seccomp '{"cmdline":"blk /test/aaaaaaaaaaaaaaax","blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/test"}}'
	../ukvm-bin.seccomp --disk=test.iso --net=tap100 blk-rumprun.seccomp '{"cmdline":"blk /test", "blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/test"}}'
	e2tail test.ext2:/bla

.PHONY: run_ukvm_rr
run_ukvm_rr: ukvm_rr
	touch dummy
	../ukvm-bin.rr --disk=dummy --net=tap100 blk-rumprun.bin '{"cmdline":"","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"10.0.0.2","mask":"16"}}'

.PHONY: clean
clean:
	rm -f blk-rumprun.bin blk-rumprun dummy blk-rumprun.ukvm blk-rumprun.seccomp test.iso test.ext2
