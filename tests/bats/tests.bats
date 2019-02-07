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

  case "${BATS_TEST_NAME}" in
  *hvt)
    [ "${STACK}" != "hvt" ] && skip "hvt not built"
    ;;
  *spt)
    [ "${STACK}" != "spt" ] && skip "spt not built"
    ;;
  *hw)
    [ "${STACK}" != "qemu" ] && skip "hw not built"
    ;;
  esac

  NET=tap100

  . ${RUMPRUN_MKCONF}
  SOLO5_SPT=${SOLO5SRC}/tenders/spt/solo5-spt
  SOLO5_HVT=${SOLO5SRC}/tenders/hvt/solo5-hvt
}

@test "cwd spt" {
  run ${TIMEOUT} --foreground 30s ${SOLO5_SPT} cwd_test.bin '{"cmdline":"cwd_test /etc","cwd":"/etc"}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"=== main() of \"cwd_test\" returned 0 ==="* ]]
}

@test "cwd hvt" {
  touch dummy
  run ${TIMEOUT} --foreground 30s ${SOLO5_HVT} --disk=dummy --net=${NET} cwd_test.bin '{"cmdline":"cwd_test /etc","cwd":"/etc"}'
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
  create_tree
  rm -f test.iso
  genisoimage -U -J -f -joliet-long -r -allow-lowercase -allow-multidot -o test.iso test_dir
  run ${TIMEOUT} --foreground 30s ${SOLO5_SPT} --disk=test.iso blk_test.bin '{"cmdline":"blk /test","blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/test"}}'
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
  rm -f test.iso
  genisoimage -U -J -f -joliet-long -r -allow-lowercase -allow-multidot -o test.iso test_dir
  run ${TIMEOUT} --foreground 30s ${SOLO5_HVT} --disk=test.iso --net=${NET} blk_test.bin '{"cmdline":"blk /test","blk":{"source":"etfs","path":"/dev/ld0a","fstype":"blk","mountpoint":"/test"}}'
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
  create_tap
  (
    ${TIMEOUT} 30s ${SOLO5_SPT} --net=${NET} test_tcp_server.bin '{"cmd":"test_tcp_server","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"10.0.0.2","mask":"16"}}'
  ) &

  sleep 1

  run curl 10.0.0.2:5000
  [ "$status" -eq 0 ]
  [[ "$output" == *"nabla"* ]]
}


@test "tcp server hvt" {
  create_tap
  (
    touch dummy
    ${TIMEOUT} 30s ${SOLO5_HVT} --disk=dummy --net=${NET} test_tcp_server.bin '{"cmd":"test_tcp_server","net":{"if":"ukvmif0","cloner":"True","type":"inet","method":"static","addr":"10.0.0.2","mask":"16"}}'
  ) &

  sleep 1

  run curl 10.0.0.2:5000
  [ "$status" -eq 0 ]
  [[ "$output" == *"nabla"* ]]
}

@test "tcp server hw" {
  skip "not implemented"
}
