SRCS+=	arch/x86/vgacons.c arch/x86/serialcons.c
SRCS+=	arch/amd64/machdep.c

CFLAGS+=	-mno-sse -mno-mmx

# squash all interrupts to a single level to
# avoid having to figure out routing
CFLAGS+=	-DBMK_SCREW_INTERRUPT_ROUTING

.PHONY: archdirs
archdirs:
	mkdir -p ${RROBJ}/platform/arch/amd64
	mkdir -p ${RROBJ}/platform/arch/x86
