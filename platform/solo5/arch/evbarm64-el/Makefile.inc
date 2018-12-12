SRCS+=	arch/evbarm64-el/machdep.c

.PHONY: archdirs
archdirs:
	mkdir -p ${RROBJ}/platform/arch/evbarm64-el
