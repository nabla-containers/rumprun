/*-
 * Copyright (c) 2014 Antti Kantee.  All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <hw/kernel.h>

#include <bmk-core/platform.h>
#include <bmk-core/printf.h>
#include <solo5.h>

#include <net/if.h>

int spldepth = 1;

unsigned long
bmk_platform_splhigh(void)
{
	return 0;
}

void
bmk_platform_splx(unsigned long x)
{
}
 
void __attribute__((noreturn))
bmk_platform_halt(const char *panicstring)
{

	if (panicstring)
		bmk_printf("PANIC: %s\n", panicstring);
	bmk_printf("halted\n");
	solo5_exit(SOLO5_EXIT_SUCCESS);
}

void rumpcomp_ukvmif_receive(void);

void
bmk_platform_cpu_block(bmk_time_t until_ns)
{
	solo5_handle_set_t ready_set;

	solo5_yield(until_ns, &ready_set);
	if (ready_set != 0) {
		rumpcomp_ukvmif_receive();
	}
}

bmk_time_t
bmk_platform_cpu_clock_monotonic(void)
{
	return solo5_clock_monotonic();
}

bmk_time_t
bmk_platform_cpu_clock_epochoffset(void)
{
	return solo5_clock_wall();
}
