.include <bsd.own.mk>

LIB=	rumpnet_ukvmif

SRCS=	if_virt.c
SRCS+=	ukvmif_component.c

RUMPTOP= ${TOPRUMP}

IFBASE=		-DVIRTIF_BASE=ukvmif

CPPFLAGS+=	-I${RUMPTOP}/librump/rumpkern -I${RUMPTOP}/librump/rumpnet
CPPFLAGS+=	-I${.CURDIR}
CPPFLAGS+=	${IFBASE}

RUMPCOMP_USER_SRCS=	 ukvmif_user.c
RUMPCOMP_USER_CPPFLAGS+= -I${.CURDIR}/..
RUMPCOMP_USER_CPPFLAGS+= -I${.CURDIR}/../solo5/include
RUMPCOMP_USER_CPPFLAGS+= -I${.CURDIR}/../../../include
RUMPCOMP_USER_CPPFLAGS+= ${IFBASE}

# XXX
.undef RUMPKERN_ONLY

.include "${RUMPTOP}/Makefile.rump"
.include <bsd.lib.mk>
.include <bsd.klinks.mk>
