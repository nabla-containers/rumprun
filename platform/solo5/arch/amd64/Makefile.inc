SRCS+=	arch/amd64/machdep.c

CFLAGS+=	-mno-sse -mno-mmx

.PHONY: archdirs
archdirs:
	mkdir -p ${RROBJ}/platform/arch/amd64
