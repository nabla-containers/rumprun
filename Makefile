build:
	./build-rr.sh -j4 -d rumprun-solo5 -o ./obj solo5

build_hw:
	./build-rr.sh -j4 -d rumprun-solo5 -o ./obj hw

clean:
	rm -rf obj*
	rm -rf rumprun
	rm -rf rumprun-solo5*
	make -C solo5 clean
