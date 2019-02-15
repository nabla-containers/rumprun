#ifndef _BMK_ARCH_AARCH64_MD_H_
#define _BMK_ARCH_AARCH64_MD_H_

#include <hw/kernel.h>

#include <bmk-core/arm/asm.h>

#define BMK_THREAD_STACK_PAGE_ORDER 3
#define BMK_THREAD_STACKSIZE ((1<<BMK_THREAD_STACK_PAGE_ORDER) \
    * BMK_PCPU_PAGE_SIZE)

#endif /* _BMK..._H_ */
