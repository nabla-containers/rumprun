build:
	CC=gcc ./build-rr.sh -j4 solo5
	cp solo5_master_62aa72a.o rumprun-solo5/rumprun-x86_64/lib/rumprun-solo5/libsolo5_ukvm.a
	cp solo5_rr-kvm_f80011ab5.o rumprun-solo5/rumprun-x86_64/lib/rumprun-solo5/libsolo5_rr.a

build_hw:
	CC=gcc ./build-rr.sh -j4 hw

clean:
	rm -rf obj-amd64*
	rm -rf rumprun
	rm -rf rumprun-solo5*
