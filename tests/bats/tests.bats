#!/usr/bin/env bats

setup() {
  cd ${BATS_TEST_DIRNAME}

  if [ -x "$(command -v timeout)" ]; then
    TIMEOUT=timeout
  elif [ -x "$(command -v gtimeout)" ]; then
    TIMEOUT=gtimeout
  else
    skip "timeout(gtimeout) is required"
  fi

  if [ -z "${STACK}" ]; then
    skip "Usage: STACK=[hvt|spt|qemu] bats tests.bats"
  fi

  case "${BATS_TEST_NAME}" in
  *hvt)
    [ "${STACK}" != "hvt" ] && skip "hvt not built"
    [ -n "${RUMPRUN_MKCONF}" ] || skip "need RUMPRUN_MKCONF set in env (run 'source [RUMPRUN]/obj/config')"
    . ${RUMPRUN_MKCONF}
    SOLO5_HVT=${SOLO5SRC}/tenders/hvt/solo5-hvt
    ;;
  *spt)
    [ "${STACK}" != "spt" ] && skip "spt not built"
    [ -n "${RUMPRUN_MKCONF}" ] || skip "need RUMPRUN_MKCONF set in env (run 'source [RUMPRUN]/obj/config')"
    . ${RUMPRUN_MKCONF}
    SOLO5_SPT=${SOLO5SRC}/tenders/spt/solo5-spt
    ;;
  *hw)
    [ "${STACK}" != "qemu" ] && skip "hw not built"
    [ -n "${RUMPRUN}" ] || skip "need RUMPRUN set in env (run 'source [RUMPRUN]/obj/config')"
    ;;
  *)
    skip "need STACK set in env"
    ;;
  esac

  NET=tap100
}

@test "cwd spt" {
  dd if=/dev/zero of=dummy bs=512 count=1 > /dev/null 2>&1
  create_tap
  run ${TIMEOUT} --foreground 30s ${SOLO5_SPT} --block:rootfs=dummy --net:tap=${NET} cwd_test.bin '{"cmdline":"cwd_test /etc","cwd":"/etc"}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"=== main() of \"cwd_test\" returned 0 ==="* ]]
}

@test "cwd hvt" {
  dd if=/dev/zero of=dummy bs=512 count=1 > /dev/null 2>&1
  create_tap
  run ${TIMEOUT} --foreground 30s ${SOLO5_HVT} --block:rootfs=dummy --net:tap=${NET} cwd_test.bin '{"cmdline":"cwd_test /etc","cwd":"/etc"}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"=== main() of \"cwd_test\" returned 0 ==="* ]]
}

@test "cwd hw" {
  skip "cwd is not implemented in the rumprun python helper script"
}

function create_tree() {
	rm -rf test_dir
	mkdir -p test_dir
	dd if=/dev/zero of=test_dir/huge bs=1M count=1k
	echo first100bytes > test_dir/aaaaaaaaaaaaaaax
	yes "........................" | dd of=test_dir/aaaaaaaaaaaaaaax conv=notrunc seek=1 bs=2k count=1024
	echo last100bytes >> test_dir/aaaaaaaaaaaaaaax
	mkdir -p test_dir/test2
	echo "test2/data2 bla bla" > test_dir/test2/data2
	mkdir -p test_dir/test3
	echo "test3/data3 bla bla" > test_dir/test3/data3
	mkdir -p test_dir/test3/test4
	echo "test3/test4/data4 bla bla" > test_dir/test3/test4/data4
	for i in `seq 1 100`; do echo $i > test_dir/blablabasdfasdfasdfasdfasdfasdfasdfasdfasdfasdf$i; done
}

@test "blk spt" {
  create_tap
  create_tree
  rm -f test.iso
  run genisoimage -U -J -f -joliet-long -r -allow-lowercase -allow-multidot -o test.iso test_dir
  run ${TIMEOUT} --foreground 30s ${SOLO5_SPT} --block:rootfs=test.iso --net:tap=tap100 blk_test.bin '{"cmdline":"blk /test","blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/test"}}'
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"."* ]]
  [[ "$output" == *".."* ]]
  [[ "$output" == *"aaaaaaaaaaaaaaax"* ]]
  [[ "$output" == *"huge"* ]]
  [[ "$output" == *"test2"* ]]
  [[ "$output" == *"test3"* ]]
  [[ "$output" == *"=== main() of \"blk\" returned 0 ==="* ]]
}

@test "blk hvt" {
  create_tree
  create_tap
  rm -f test.iso
  run genisoimage -U -J -f -joliet-long -r -allow-lowercase -allow-multidot -o test.iso test_dir
  run ${TIMEOUT} --foreground 30s ${SOLO5_HVT} --block:rootfs=test.iso --net:tap=${NET} blk_test.bin '{"cmdline":"blk /test","blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/test"}}'
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"."* ]]
  [[ "$output" == *".."* ]]
  [[ "$output" == *"aaaaaaaaaaaaaaax"* ]]
  [[ "$output" == *"huge"* ]]
  [[ "$output" == *"test2"* ]]
  [[ "$output" == *"test3"* ]]
  [[ "$output" == *"=== main() of \"blk\" returned 0 ==="* ]]
}

@test "blk hw" {
  skip "not implemented"
}

function create_tap() {
  run ip link show tap100
  if [ "$status" -ne 0 ]; then
    [ $(id -u) -ne 0 ] && skip "need root to create a tap"
    run ip tuntap add ${NET} mode tap
    run ip addr add 10.0.0.1/24 dev ${NET}
    ip link set dev ${NET} up
  fi
}

@test "tcp server spt" {
  dd if=/dev/zero of=dummy bs=512 count=1 > /dev/null 2>&1
  create_tap
  (
    ${TIMEOUT} 30s ${SOLO5_SPT} --block:rootfs=dummy --net:tap=${NET} tcp_server_test.bin '{"cmd":"test_tcp_server","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"10.0.0.2","mask":"16"}}'
  ) &

  run wget --retry-connrefused --tries=5 --waitretry=1 -q -O - 10.0.0.2:5000
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nabla"* ]]
}

@test "tcp server hvt" {
  create_tap
  (
    dd if=/dev/zero of=dummy bs=512 count=1 > /dev/null 2>&1
    ${TIMEOUT} 30s ${SOLO5_HVT} --block:rootfs=dummy --net:tap=${NET} tcp_server_test.bin '{"cmd":"test_tcp_server","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"10.0.0.2","mask":"16"}}'
  ) &

  run wget --retry-connrefused --tries=5 --waitretry=1 -q -O - 10.0.0.2:5000
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"nabla"* ]]
}

@test "tcp server hw" {
  skip "not implemented"
}

@test "file rename spt" {
  skip "Not working in rumprun"
  create_tap
  dd if=/dev/zero of=data.ext2 count=1024 bs=1024
  mkfs.ext2 data.ext2
  run ${TIMEOUT} 30s ${SOLO5_SPT} --block:rootfs=data.ext2 --net:tap=${NET} file_rename_test.bin '{"cmdline":"test_rename /test","blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/test"}}'
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"=== main() of \"test_rename\" returned 0 ==="* ]]
}

@test "file rename hvt" {
  skip "Not working in rumprun"
  create_tap
  dd if=/dev/zero of=data.ext2 count=1024 bs=1024
  mkfs.ext2 data.ext2
  run ${TIMEOUT} 30s ${SOLO5_HVT} --block:rootfs=data.ext2 --net:tap=${NET} file_rename_test.bin '{"cmdline":"test_rename /test","blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/test"}}'
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"=== main() of \"test_rename\" returned 0 ==="* ]]
}

@test "file rename hw" {
  skip "not implemented"
}
