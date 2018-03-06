build:
	./build-rr.sh -j4 -d rumprun-solo5 -o ./obj solo5 build
	./build-rr.sh -j4 -d rumprun-solo5 -o ./obj solo5 install
	cp solo5_master_ce5a3d4.o rumprun-solo5/rumprun-x86_64/lib/rumprun-solo5/libsolo5_ukvm.a
	cp solo5_ukvm-linux-seccomp_01dc134.o rumprun-solo5/rumprun-x86_64/lib/rumprun-solo5/libsolo5_seccomp.a

build_hw:
	CC=gcc ./build-rr.sh -j4 -d rumprun-solo5 -o ./obj hw

clean:
	rm -rf obj*
	rm -rf rumprun
	rm -rf rumprun-solo5*
