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

#include <hw/types.h>
#include <hw/kernel.h>

#include <bmk-core/core.h>
#include <bmk-core/mainthread.h>
#include <bmk-core/sched.h>
#include <bmk-core/printf.h>

#include <bmk-core/solo5.h>
#include <bmk-core/pgalloc.h>

#define HEAP_SIZE	(400e6) // 400 MBs hardcoded XXX

int solo5_app_main(char *cmdline);

int solo5_app_main(char *cmdline)
{
	unsigned long heap, heap_aligned;

	cons_init();
	bmk_printf("rump kernel bare metal bootstrap\n\n");

	bmk_sched_init();

	heap = (unsigned long) solo5_calloc(HEAP_SIZE, 1);
	bmk_assert(heap != 0);

	heap_aligned = bmk_round_page(heap);

	bmk_core_init(BMK_THREAD_STACK_PAGE_ORDER);

	bmk_pgalloc_loadmem(heap_aligned, heap + HEAP_SIZE);
        bmk_memsize = heap + HEAP_SIZE - heap_aligned;

	bmk_sched_startmain(bmk_mainthread, cmdline);

	/* not reachable */
	solo5_exit();
}
