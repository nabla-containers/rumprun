#include <bmk-core/arm/asm.h>

ENTRY(bmk_cpu_sched_bouncer)
	ldp x0, x1, [sp], #16
	br x1
	bl bmk_sched_exit
END(bmk_cpu_sched_bouncer)

/*
 * x0 = previous thread
 * x1 = new thread
 */
ENTRY(bmk_cpu_sched_switch)
	stp x29, x30, [sp, #-96]!
	stp x19, x20, [sp, #16]
	stp x21, x22, [sp, #32]
	stp x23, x24, [sp, #48]
	stp x25, x26, [sp, #64]
	stp x27, x28, [sp, #80]
	mov x9, sp
	adr x10, 1f
	stp x9, x10, [x0]
	ldp x9, x10, [x1]
	mov sp, x9
	br x10
	bl bmk_sched_exit
1:	
	ldp x19, x20, [sp, #16]
	ldp x21, x22, [sp, #32]
	ldp x23, x24, [sp, #48]
	ldp x25, x26, [sp, #64]
	ldp x27, x28, [sp, #80]
	ldp x29, x30, [sp], #96
	ret
END(bmk_cpu_sched_switch)
