#! /usr/bin/env sh
#
# Copyright (c) 2014, 2015 Antti Kantee <pooka@iki.fi>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

set -eu

die ()
{

	echo '>> ERROR:'
	echo '>>' $*
	exit 1
}

helpme ()
{

	printf "Usage: $0 [-d destdir] [-j num] [-k] [-o objdir] [-q]\n"
	printf "\t[-s srcdir] hw|xen|solo5 [build] [install] [-- buildrump.sh opts]\n"
	printf "\n"
	printf "\t-d: destination base directory, used by \"install\".\n"
	printf "\t-j: run <num> make jobs simultaneously.\n"
	printf "\t-q: quiet(er) build.  option may be specified twice.\n\n"
	printf "\tThe default actions are \"build\" and \"install\"\n\n"

	printf "Expert-only options:\n"
	printf "\t-o: use non-default object directory\n"
	printf "\t-k: build kernel only, without libc or tools\n"
	printf "\t-s: specify alternative src-netbsd location\n\n"
	printf "\tbuildrump.sh opts are passed to buildrump.sh\n"
	printf "\n"
	printf "The toolchain is picked up from the environment.  See the\n"
	printf "Rumprun wiki for more information.\n"
	exit 1
}

CC=${CC:-cc}

BUILDRUMP=$(pwd)/buildrump.sh
SOLO5SRC=$(pwd)/solo5

# overriden by script if true
HAVECXX=false

: ${GIT:=git}

# figure out where gmake lies
if [ -z "${MAKE:-}" ]; then
	MAKE=make
	! type gmake >/dev/null 2>&1 || MAKE=gmake
fi
type ${MAKE} >/dev/null 2>&1 || die '"make" required but not found'


#
# SUBROUTINES
#

abspath ()
{

	eval mypath=\${$1}
	case ${mypath} in
	/*)
		;;
	*)
		mypath="$(pwd)/${mypath}"
	esac

	eval ${1}="\${mypath}"
}

parseargs ()
{

	RRDEST=
	KERNONLY=false
	RROBJ=
	RUMPSRC=src-netbsd
	STDJ=-j4
	EXTSRC=

	DObuild=false
	DOinstall=false

	orignargs=$#
	while getopts '?d:hj:ko:qs:' opt; do
		case "$opt" in
		'j')
			[ -z "$(echo ${OPTARG} | tr -d '[0-9]')" ] \
			    || die argument to -j must be a number
			STDJ=-j${OPTARG}
			;;
		'd')
			RRDEST="${OPTARG}"
			;;
		'k')
			KERNONLY=true
			;;
		'o')
			RROBJ="${OPTARG}"
			;;
		's')
			RUMPSRC=${OPTARG}
			EXTSRC=-extsrc
			;;
		'q')
			BUILD_QUIET=${BUILD_QUIET:=-}q
			;;
		'h'|'?')
			helpme
			exit 1
		esac
	done
	shift $((${OPTIND} - 1))

	# are we on a git branch which is not master?
	if type ${GIT} >/dev/null; then
		GITBRANCH=$(${GIT} rev-parse --abbrev-ref HEAD 2>/dev/null)
		if [ ${GITBRANCH} = "master" -o ${GITBRANCH} = "HEAD" ]; then
			GITBRANCH=
		else
			GITBRANCH=-${GITBRANCH}
		fi
	else
		GITBRANCH=
	fi

	[ -n "${RRDEST}" ] || RRDEST=./rumprun${GITBRANCH}${EXTSRC}

	: ${BUILD_QUIET:=}

	[ $# -gt 0 ] || helpme

	PLATFORM=$1
	export PLATFORMDIR=platform/${PLATFORM}
	[ -d ${PLATFORMDIR} ] || die Platform \"$PLATFORM\" not supported!
	abspath PLATFORMDIR
	shift

	dodefault=true
	while [ $# -gt 0 ]; do
		if [ $1 = '--' ]; then
			shift
			break
		else
			case $1 in
			build|install)
				eval DO${1}=true
				;;
			*)
				die invalid argument $1
				;;
			esac
			dodefault=false
			shift
		fi
	done
	if ${dodefault}; then
		DObuild=true
		DOinstall=true
	fi

	case ${RUMPSRC} in
	/*)
		;;
	*)
		RUMPSRC=$(pwd)/${RUMPSRC}
		;;
	esac

	export RUMPSRC
	export BUILD_QUIET

	ARGSSHIFT=$((${orignargs} - $#))
}

checksubmodules ()
{

	# We assume that if the git submodule command fails, it's because
	# we're using external $RUMPSRC.
	if git submodule status ${RUMPSRC} 2>/dev/null | grep -q '^-' \
	    || git submodule status ${BUILDRUMP} 2>/dev/null | grep -q '^-' \
	        || git submodule status ${SOLO5SRC} 2>/dev/null | grep -q '^-';
	then
		echo '>>'
		echo '>> submodules missing.  run "git submodule update --init"'
		echo '>>'
		exit 1
	fi

	if git submodule status ${RUMPSRC} 2>/dev/null | grep -q '^+' \
	    || git submodule status ${BUILDRUMP} 2>/dev/null | grep -q '^+'
	then
		echo '>>'
		echo '>> Your git submodules are out-of-date'
		echo '>> Forgot to run "git submodule update" after pull?'
		echo '>> (sleeping for 5s, press ctrl-C to abort)'
		echo '>>'
		echo -n '>>'
		for x in 1 2 3 4 5; do echo -n ' !' ; sleep 1 ; done
	fi
}

# check that the necessary things are available on the build system
probeprereqs ()
{

	if [ "${PLATFORM}" = "xen" ]; then (
		. "${RROBJ}/config.sh"
		# probe location of Xen headers
		found=false
		for loc in ${XEN_HEADERS:-} /usr/pkg/include/xen /usr/include/xen; do
			if printf '#include <stdint.h>\n#include <xen.h>\n'\
			    | ${CC} -I${loc} -x c - -c -o /dev/null \
			    >/dev/null 2>&1 ; then
				found=true
				break
			fi
		done

		if ${found}; then
			echo "XEN_HEADERS=${loc}" >> ${RROBJ}/config.mk
			echo "XEN_HEADERS=\"${loc}\"" >> ${RROBJ}/config.sh
		else
			echo '>> You need to provide Xen headers.'
			echo '>> The exactly source depends on your system'
			echo '>> (e.g. libxen-dev package on some systems)'
			die Xen headers not found
		fi )
	fi
}

checkprevbuilds ()
{

	[ "${PLATFORM}" = "xen" ] || return 0

	if [ -f .prevbuild ]; then
		. ./.prevbuild
		: ${PB_KERNONLY:=false} # "bootstrap", remove in a few months
		if [ "${PB_MACHINE}" != "${MACHINE}" \
		    -o "${PB_KERNONLY}" != "${KERNONLY}" \
		]; then
			echo '>> ERROR:'
			echo '>> Building for multiple machine combos'
			echo '>> from the same rumprun source tree is currently'
			echo '>> not supported.  See rumprun issue #35.'
			printf '>> %20s: %s nolibc=%s\n' 'Previously built' \
			    ${PB_MACHINE} ${PB_KERNONLY}
			printf '>> %20s: %s nolibc=%s\n' 'Now building' \
			    ${MACHINE} ${KERNONLY}
			exit 1
		fi
	else
		echo PB_MACHINE=${MACHINE} > ./.prevbuild
		echo PB_KERNONLY=${KERNONLY} >> ./.prevbuild
	fi
}

setvars ()
{

	# probe us some vars (_tmp-dance catches possible error for -e)
	_tmp="$(${BUILDRUMP}/buildrump.sh "$@" probe)"
	eval "${_tmp}"
	MACHINE="${BUILDRUMP_MACHINE}"
	MACHINE_GNU_ARCH="${BUILDRUMP_MACHINE_GNU_ARCH}"

	if [ -z "${RROBJ}" ]; then
		RROBJ="./obj-${MACHINE}-${PLATFORM}${GITBRANCH}${EXTSRC}"
		${KERNONLY} && RROBJ="${RROBJ}-kernonly"
	fi
	abspath RROBJ
	STAGING="${RROBJ}/dest.stage"
	BROBJ="${RROBJ}/buildrump.sh"
	RUMPTOOLS="${RROBJ}/rumptools"

	abspath RRDEST
	abspath RUMPSRC
}

checktools ()
{

	# Check that a clang build is not attempted.
	[ -z "${BUILDRUMP_HAVE_LLVM}" ] \
	    || die rumprun does not yet support clang ${CC:+(\$CC: $CC)}

	delay=5

	# check that gcc is modern enough
	vers=$(${CC} -E -dM - < /dev/null | LANG=C awk '
	    /__GNUC__/ {version += 100*$3}
	    /__GNUC_MINOR__/ {version += $3}
	    END { print version; if (version) exit 0; exit 1; }') \
		|| unable to probe cc version
	if [ ${vers} -lt 500 ]; then
		die gcc is too old, 6.0 or later is recommended. ${CC:+(\$CC: $CC)}
	elif [ ${vers} -lt 600 ]; then
		[ "${MACHINE_GNU_ARCH}" != "aarch64" ] && \
			die gcc is too old, need 6.0 or later. ${CC:+(\$CC: $CC)}
		echo '>>'
		echo ">> WARNING: gcc is old. ${CC:+(\$CC: $CC)}"
		echo '>> Version 6.0 or later is recommended.'
		echo ">> (continuing in ${delay} seconds)"
		echo '>>'
		sleep ${delay}
	fi

	# check that ld is modern enough
	vers=$(${CC} -Wl,--version 2>&1 | LANG=C awk '
	    /GNU ld/{version += 100*$NF}
	    END { print version; if (version) exit 0; exit 1; }') \
		|| die unable to probe ld version
	if [ ${vers} -lt 222 ]; then
		die ld is too old, need 2.22 or later. probed version: ${vers}
	elif [ ${vers} -lt 225 ]; then
		echo '>>'
		echo ">> WARNING: ld is old. probed version: ${vers}"
		echo '>> Version 2.25 or later is recommended.'
		echo ">> (continuing in ${delay} seconds)"
		echo '>>'
		sleep ${delay}
	fi
}

buildrump ()
{

	checktools
	checkprevbuilds

	RR_USE_TLS=
	FREQ_SETUP=
	# Below are two customizations for solo5.
	# 1. Solo5 does not support using segment based TLS (TLS
	#    bases stored in %fs/%gs).
	# 2. Increasing the clock rate frequency (from 10 to 100)
	#    improves overall performance for network throughput
	#    and web servers requests/sec. The reason why this is
	#    important in solo5 and not qemu or xen is that solo5
	#    only supports polling IO (it has no interrupts). So,
	#    very frequent polling, done every clock tick, is good.
	if [ "${PLATFORM}" = "solo5" ]; then
		FREQ_SETUP="-F CFLAGS=-DHZ=100"
		RR_USE_TLS="no"
	else
		RR_USE_TLS="yes"
	fi

	TLSCFLAGS=
	if [ "${RR_USE_TLS}" = "yes" ]; then
		CURLWP_METHOD=__thread
		TLSCFLAGS="-F CFLAGS=-DRR_USE_TLS"
	else
		CURLWP_METHOD=hypercall
		TLSCFLAGS="-F CFLAGS=-D_PTHREAD_GETTCB_EXT=_lwp_get_tls_tcb -F CFLAGS=-fno-stack-protector"
	fi

	extracflags=
	[ "${MACHINE_GNU_ARCH}" = "x86_64" ] \
	    && extracflags='-F CFLAGS=-mno-red-zone'

	# Disable new errors on GCC 7 which break netbsd-src compilation
	#
	[ `${CC} -dumpversion | cut -f1 -d.` -ge 7 ] \
		&& extracflags="$extracflags -F CPPFLAGS=-Wimplicit-fallthrough=0"
	[ `${CC} -dumpversion | cut -f1 -d.` -ge 7 ] \
		&& extracflags="$extracflags -F CPPFLAGS=-Wno-maybe-uninitialized"
	[ `${CC} -dumpversion | cut -f1 -d.` -ge 7 ] \
		&& extracflags="$extracflags -F CPPFLAGS=-Wno-cast-function-type"
	[ `${CC} -dumpversion | cut -f1 -d.` -ge 7 ] \
		&& extracflags="$extracflags -F CPPFLAGS=-Wno-tautological-compare"
	[ `${CC} -dumpversion | cut -f1 -d.` -ge 7 ] \
		&& extracflags="$extracflags -F CPPFLAGS=-Wno-attributes"


	extracflags="${extracflags} ${TLSCFLAGS} ${FREQ_SETUP}"

	# build tools
	${BUILDRUMP}/buildrump.sh ${BUILD_QUIET} ${STDJ} -k		\
	    -s ${RUMPSRC} -T ${RUMPTOOLS} -o ${BROBJ} -d ${STAGING}	\
	    -V MKPIC=no -V RUMP_CURLWP=${CURLWP_METHOD}			\
	    -V RUMP_KERNEL_IS_LIBC=1 -V BUILDRUMP_SYSROOT=yes		\
	    ${extracflags} "$@" tools

	echo '>>'
	echo '>> Now that we have the appropriate tools, performing'
	echo '>> further setup for rumprun build'
	echo '>>'

	RUMPMAKE=${RUMPTOOLS}/rumpmake

	TOOLTUPLE=$(${RUMPMAKE} -f bsd.own.mk \
	    -V '${MACHINE_GNU_PLATFORM:S/--netbsd/-rumprun-netbsd/}')

	[ $(${RUMPMAKE} -f bsd.own.mk -V '${_BUILDRUMP_CXX}') != 'yes' ] \
	    || HAVECXX=true

	makeconfig ${RROBJ}/config.mk ''
	makeconfig ${RROBJ}/config.sh \"
	# XXX: gcc is hardcoded
	cat > ${RROBJ}/config << EOF
export RUMPRUN_MKCONF="${RROBJ}/config.mk"
export RUMPRUN_SHCONF="${RROBJ}/config.sh"
export RUMPRUN_BAKE="${RRDEST}/bin/rumprun-bake"
export RUMPRUN_CC="${RRDEST}/bin/${TOOLTUPLE}-gcc"
export RUMPRUN_CXX="${RRDEST}/bin/${TOOLTUPLE}-g++"
export RUMPRUN="${RRDEST}/bin/rumprun"
export RUMPSTOP="${RRDEST}/bin/rumpstop"
EOF
	cat > "${RROBJ}/config-PATH.sh" << EOF
export PATH="${RRDEST}/bin:\${PATH}"
EOF
	export RUMPRUN_MKCONF="${RROBJ}/config.mk"

	probeprereqs

	cat >> ${RUMPTOOLS}/mk.conf << EOF
.if defined(LIB) && \${LIB} == "pthread"
.PATH:  $(pwd)/lib/librumprun_base/pthread
PTHREAD_MAKELWP=pthread_makelwp_rumprun.c
CPPFLAGS.pthread_makelwp_rumprun.c= -I$(pwd)/include
.endif  # LIB == pthread
EOF
	[ -z "${PLATFORM_MKCONF}" ] \
	    || echo "${PLATFORM_MKCONF}" >> ${RUMPTOOLS}/mk.conf

	echo "RUMPRUN_TUPLE=${TOOLTUPLE}" >> ${RUMPTOOLS}/mk.conf

	# build rump kernel
	${BUILDRUMP}/buildrump.sh ${BUILD_QUIET} ${STDJ} -k		\
	    -s ${RUMPSRC} -T ${RUMPTOOLS} -o ${BROBJ} -d ${STAGING}	\
	    "$@" build kernelheaders install

	echo '>>'
	echo '>> Rump kernel components built.  Proceeding to build'
	echo '>> rumprun bits'
	echo '>>'
}

buildapptools ()
{

	${MAKE} -C app-tools BUILDRR=true
	${MAKE} -C app-tools BUILDRR=true install
}

builduserspace ()
{

	usermtree ${STAGING}

	LIBS="$(stdlibs ${RUMPSRC})"
	! ${HAVECXX} || LIBS="${LIBS} $(stdlibsxx ${RUMPSRC})"

	userincludes ${RUMPSRC} ${LIBS} $(pwd)/lib/librumprun_tester
	for lib in ${LIBS}; do
		makeuserlib ${lib}
	done
}

buildpci ()
{

	if eval ${PLATFORM_PCI_P}; then
		(
			cd ${PLATFORMDIR}/pci
			${RUMPMAKE} ${STDJ} obj
			${RUMPMAKE} ${STDJ} dependall
			${RUMPMAKE} ${STDJ} install
		)
	fi
}

installsolo5libs ()
{

	SPTLIB=${RRDEST}/rumprun-${MACHINE_GNU_ARCH}/lib/rumprun-${PLATFORM}/libsolo5_spt.a
	HVTLIB=${RRDEST}/rumprun-${MACHINE_GNU_ARCH}/lib/rumprun-${PLATFORM}/libsolo5_hvt.a

	# The reason for this very strange objcopy is that both solo5.o and
	# rumprun's libc.a define a stack guard.
	objcopy --redefine-sym __stack_chk_fail=__stack_chk_fail_solo5 \
		--redefine-sym __stack_chk_guard=__stack_chk_guard_solo5 \
		solo5/bindings/spt/solo5_spt.o ${SPTLIB}

	objcopy --redefine-sym __stack_chk_fail=__stack_chk_fail_solo5 \
		--redefine-sym __stack_chk_guard=__stack_chk_guard_solo5 \
		solo5/bindings/hvt/solo5_hvt.o ${HVTLIB}
}

wraponetool ()
{

	configfile=$1
	tool=$2
	quote=$3

	tpath=$(${RUMPMAKE} -f bsd.own.mk -V "\${${tool}}")
	if ! [ -n "${tpath}" -a -x ${tpath} ]; then
		die Could not locate buildrump.sh tool \"${tool}\".
	fi
	echo "${tool}=${quote}${tpath}${quote}" >> ${configfile}
}

makeconfig ()
{

	quote="${2}"

	echo "BUILDRUMP=${quote}${BUILDRUMP}${quote}" > ${1}
	echo "RUMPSRC=${quote}${RUMPSRC}${quote}" >> ${1}
	echo "RUMPMAKE=${quote}${RUMPMAKE}${quote}" >> ${1}
	echo "BUILDRUMP_TOOLFLAGS=${quote}${RUMPTOOLS}/toolchain-conf.mk${quote}" >> ${1}
	echo "MACHINE=${quote}${MACHINE}${quote}" >> ${1}
	echo "MACHINE_GNU_ARCH=${quote}${MACHINE_GNU_ARCH}${quote}" >> ${1}
	echo "TOOLTUPLE=${quote}${TOOLTUPLE}${quote}" >> ${1}
	echo "KERNONLY=${quote}${KERNONLY}${quote}" >> ${1}
	echo "PLATFORM=${quote}${PLATFORM}${quote}" >> ${1}

	[ "${PLATFORM}" = "solo5" ] && ( echo "SOLO5SRC=${quote}${SOLO5SRC}${quote}" >> ${1} )

	echo "RRDEST=${quote}${RRDEST}${quote}" >> ${1}
	echo "RROBJ=${quote}${RROBJ}${quote}" >> ${1}

	# wrap mandatory toolchain bits
	for t in AR AS CC CPP LD NM OBJCOPY OBJDUMP RANLIB READELF \
            SIZE STRINGS STRIP; do
		wraponetool ${1} ${t} "${quote}"
	done

	# c++ is optional, wrap it iff available
	if ${HAVECXX}; then
		echo "CONFIG_CXX=yes" >> ${1}
		wraponetool ${1} CXX "${quote}"
	else
		echo "CONFIG_CXX=no" >> ${1}
	fi

	# Check for if compiler supports -no-pie and save to EXTRACCFLAGS
	gccnopie=
	if [ -z "`echo 'int p=1;' | ${CC} -no-pie -S -o /dev/null -x c - 2>&1`" ]; then
		gccnopie=-no-pie
	fi
	echo "EXTRACCFLAGS=${quote}${gccnopie}${quote}" >> ${1}

}

dobuild ()
{

	checksubmodules

	. ${BUILDRUMP}/subr.sh

	PLATFORM_MKCONF=
	. ${PLATFORMDIR}/platform.conf

	buildrump "$@"
	mkdir -p ${STAGING}/rumprun-${MACHINE_GNU_ARCH}/lib/rumprun-${PLATFORM}\
	    || die cannot create libdir

	${KERNONLY} || buildapptools
	${MAKE} -C ${PLATFORMDIR} links
	${KERNONLY} || builduserspace

	buildpci

	[ "${PLATFORM}" = "solo5" ] && make -C ${SOLO5SRC}

	# do final build of the platform bits
	( cd ${PLATFORMDIR} \
	    && ${MAKE} BUILDRR=true \
	    && ${MAKE} BUILDRR=true install || exit 1)
	[ $? -eq 0 ] || die platform make failed!
}

doinstall ()
{

	# sanity check
	[ -d "${RROBJ}" ] \
	    || die 'No objdir. No build or build with different params?'

	. "${RROBJ}/config.sh"

	# default used to be a symlink, so this is for "compat".
	# remove in a few months.
	rm -f ${RRDEST} > /dev/null 2>&1 || true

	mkdir -p ${RRDEST}/rumprun-${MACHINE_GNU_ARCH}/include \
	    || die cannot create ${RRDEST}/include/rumprun

	# copy everything except include
	(
		# first, move things to where we want them to be
		cd ${STAGING}
		rm -rf lib/pkgconfig
		find lib -maxdepth 1 -name librump\*.a \
		    -exec mv -f '{}' rumprun-${MACHINE_GNU_ARCH}/lib/rumprun-${PLATFORM}/ \;
		find lib -maxdepth 1 -name \*.a \
		    -exec mv -f '{}' rumprun-${MACHINE_GNU_ARCH}/lib/ \;

		# make sure special cases are visible everywhere
		for x in c pthread ; do
			rm -f rumprun-${MACHINE_GNU_ARCH}/lib/rumprun-${PLATFORM}/lib${x}.a
			ln -s ../lib${x}.a \
			    rumprun-${MACHINE_GNU_ARCH}/lib/rumprun-${PLATFORM}/lib${x}.a
		done
		find . -maxdepth 1 \! -path . \! -path ./include\* \
		    | xargs tar -cf -
	) | (cd ${RRDEST} ; tar -xf -)

	[ "${PLATFORM}" = "solo5" ] && installsolo5libs

	# copy include to destdir/include/rumprun
	( cd ${STAGING}/include ; tar -cf - . ) \
	    | ( cd ${RRDEST}/rumprun-${MACHINE_GNU_ARCH}/include ; tar -xf - )
}

#
# BEGIN SCRIPT
#

parseargs "$@"
shift ${ARGSSHIFT}

setvars "$@"
${DObuild} && dobuild "$@"
${DOinstall} && doinstall

# echo some useful information for the user
echo
echo '>>'
echo ">> Finished $0 for ${PLATFORM}"
echo '>>'
echo ">> For Rumprun developers (if you're not sure, you don't need it):"
echo ". \"${RROBJ}/config\""
echo '>>'
if ${DObuild}; then
	printf ">> toolchain tuple: ${TOOLTUPLE}\n"
	printf ">> cc wrapper: %s-%s\n" \
	   ${TOOLTUPLE} "$(${RUMPMAKE} -f bsd.own.mk -V '${ACTIVE_CC}')"
fi
if ${DOinstall}; then
	printf ">> installed to \"%s\"\n" ${RRDEST}
	echo '>>'
	echo '>> Set tooldir to front of $PATH (bourne-style shells)'
	echo ". \"${RROBJ}/config-PATH.sh\""
fi
echo '>>'
echo ">> $0 ran successfully"
exit 0
