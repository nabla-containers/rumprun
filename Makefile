NCORES = $(shell grep -c ^processor /proc/cpuinfo)
DESTDIR ?= rumprun-solo5

build:
	./build-rr.sh -j$(NCORES) -d ${DESTDIR} -o ./obj solo5

build_hw:
	CC=gcc ./build-rr.sh -j$(NCORES) -d rumprun-solo5 -o ./obj hw

clean:
	rm -rf obj*
	rm -rf rumprun
	rm -rf rumprun-solo5*
	make -C solo5 clean
