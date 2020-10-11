#!/bin/sh

# This script builds all tests, including the one which
# tests for configure.  I'm sure it would be possible to do it
# with just "make", but a script seems vastly simpler now.

# we know, we knooooooow
export RUMPRUN_WARNING_STFU=please

set -e

TESTMODE=apptools
TESTCONFIGURE=true
TESTCMAKE=$(which cmake || echo "")
RUMPBAKE_PLATFORM=

while getopts 'kqhp:' opt; do
	case "$opt" in
	'k')
		TESTMODE=kernonly
		;;
	'q')
		TESTCONFIGURE=false
		;;
	'p')
		RUMPBAKE_PLATFORM="${OPTARG}"
		;;
	'h'|'?')
		echo "$0 [-k|-q]"
		exit 1
	esac
done
shift $((${OPTIND} - 1))

# XXX: sourcing the file while aiming to use app-tools is plain wrong
[ -n "${RUMPRUN_SHCONF}" ] || { echo '>> need RUMPRUN_SHCONF'; exit 1; }
. "${RUMPRUN_SHCONF}"
unset CC
unset CXX

cd "$(dirname $0)"

test_apptools()
{

	if [ -z "$RUMPBAKE_PLATFORM" ]; then
		case ${PLATFORM} in
		hw)
			RUMPBAKE_PLATFORM='hw_generic'
			;;
		xen)
			RUMPBAKE_PLATFORM='xen_pv'
			;;
		solo5)
			RUMPBAKE_PLATFORM='solo5_spt'
			;;
		*)
			echo ">> unknown platform \"$PLATFORM\""
			exit 1
		esac
	fi

	export PATH="${RRDEST}/bin:${PATH}"
	export RUMPBAKE_PLATFORM

	make

	if ${TESTCONFIGURE}; then
		(
			cd configure
			./configure --host=${TOOLTUPLE}
			make
		)
	fi

	if [ -n "${TESTCMAKE}" ]; then
		(
			rm -rf cmake/build
			mkdir -p cmake/build
			cd cmake/build
			cmake -DCMAKE_TOOLCHAIN_FILE=${RRDEST}/rumprun-${MACHINE_GNU_ARCH}/share/${TOOLTUPLE}-toolchain.cmake ..
			make
		)
	fi
}

test_kernonly()
{
	if [ -z "${MAKE}" ]; then
		MAKE=make
		! type gmake >/dev/null 2>&1 || MAKE=gmake
	fi

	${MAKE} PLATFORM=${PLATFORM} kernonly-tests
}

test_${TESTMODE}

exit 0
