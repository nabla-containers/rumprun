build:
	CC=gcc ./build-rr.sh solo5
	cp solo5.o rumprun-solo5/rumprun-x86_64/lib/rumprun-solo5/libsolo5.a

clean:
	rm -rf obj-amd64*
	rm -rf rumprun
	rm -rf rumprun-solo5
