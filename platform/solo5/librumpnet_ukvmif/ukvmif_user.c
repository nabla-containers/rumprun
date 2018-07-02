/*	$NetBSD: virtif_user.c,v 1.3 2014/03/14 10:06:22 pooka Exp $	*/

/*
 * Copyright (c) 2013 Antti Kantee.  All Rights Reserved.
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

#ifndef _KERNEL
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/uio.h>

#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <poll.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

//#include <rump/rumpuser_component.h>

#include <bmk-rumpuser/core_types.h>
#include <bmk-rumpuser/rumpuser.h>

#include <bmk-core/errno.h>
#include <bmk-core/memalloc.h>
#include <bmk-core/string.h>
#include <bmk-core/sched.h>

#include <net/if_ether.h>

#include "if_virt.h"
#include "virtif_user.h"
#include <solo5.h>

#if VIFHYPER_REVISION != 20140313
#error VIFHYPER_REVISION mismatch
#endif

#define PKT_BUFFER_LEN 1526

struct virtif_user {
	struct virtif_sc *viu_virtifsc;
	struct bmk_thread *viu_rcvthr;
	int viu_dying;
};

static struct solo5_net_info ni;
int
VIFHYPER_MAC(uint8_t **enaddr)
{
        solo5_net_info(&ni);
	*enaddr = ni.mac_address;
	return 0;
}

int
do_receive(void);

static void
rcvthread(void *arg)
{
	struct virtif_user *viu = arg;
	uint64_t sleep_ns = 1e9/HZ;

	/* give us a rump kernel context */
	rumpuser__hyp.hyp_schedule();
	rumpuser__hyp.hyp_lwproc_newlwp(0);
	rumpuser__hyp.hyp_unschedule();

 again:
	while (!viu->viu_dying) {
		if (do_receive() != 0) {
			viu->viu_rcvthr = bmk_current;
			bmk_sched_blockprepare_timeout(solo5_clock_monotonic() + sleep_ns);
			bmk_sched_block();
			viu->viu_rcvthr = NULL;
		}
		goto again;
	}

	solo5_console_write("bye from rcv\n",13);
	assert(viu->viu_dying);
}

int
VIFHYPER_DYING(struct virtif_user *viu)
{

	/* this may take a while to pick up
	   should perhaps make process scheduled */
	viu->viu_dying = 1;

	return 0;
}


static struct virtif_user *_viu = NULL;

int
VIFHYPER_CREATE(const char *devstr, struct virtif_sc *vif_sc, uint8_t *enaddr,
	struct virtif_user **viup)
{
	struct virtif_user *viu = NULL;

	viu = bmk_memalloc(sizeof(*viu), 0, BMK_MEMWHO_RUMPKERN);
	if (viu == NULL) {
		solo5_console_write("create  fail\n",13);
		solo5_exit(1);
	}

	viu->viu_virtifsc = vif_sc;

	viu->viu_rcvthr = bmk_sched_create("ukvmifp",
	    NULL, 1, rcvthread, viu, NULL, 0);
	if (! viu->viu_rcvthr) {
		solo5_console_write("thread  fail\n",13);
		solo5_exit(1);
	}

	*viup = viu;
	_viu = viu;
	return 0;
}

void
VIFHYPER_RECEIVE(void)
{
	if (_viu && _viu->viu_rcvthr) {
		bmk_sched_wake(_viu->viu_rcvthr);
	}
}

char data[9000];

int
do_receive(void)
{
	struct iovec iov[1];
	unsigned long len = PKT_BUFFER_LEN;

	// XXX shouldn't abort if error
	if (solo5_net_read(data, PKT_BUFFER_LEN, &len) != 0) {
		return 1;
	}

	iov[0].iov_base = data;
	iov[0].iov_len = len;

	rumpuser__hyp.hyp_schedule();
	VIF_DELIVERPKT(iov, 1);
	rumpuser__hyp.hyp_unschedule();
	return 0;
}

char d[9000];

void
VIFHYPER_SEND(struct virtif_user *viu,
	struct iovec *iov, size_t iovlen)
{
	size_t tlen, i;
	int nlocks;
	char *d0;

	rumpkern_unsched(&nlocks, NULL);
	/*
	 * ukvm doesn't do scatter-gather, so just simply
	 * copy the data into one lump here.  drop packet if we
	 * can't allocate temp memory space.
	 */
	if (iovlen == 1) {
		solo5_net_write(iov->iov_base, iov->iov_len);
		rumpkern_sched(nlocks, NULL);
		return;
	} else {
		for (i = 0, tlen = 0; i < iovlen; i++) {
			tlen += iov[i].iov_len;
		}

		/*
		 * allocate the temp space from RUMPKERN instead of BMK
		 * since there are no huge repercussions if we fail or
		 * succeed.
		 */
		d0 = (char *)d;

		for (i = 0; i < iovlen; i++) {
			bmk_memcpy(d0, iov[i].iov_base, iov[i].iov_len);
			d0 += iov[i].iov_len;
		}
	}

	// XXX: check for error
	solo5_net_write(d, tlen);

	rumpkern_sched(nlocks, NULL);
	return;
}
#endif
