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
#include <bmk-core/solo5.h>

#if VIFHYPER_REVISION != 20140313
#error VIFHYPER_REVISION mismatch
#endif

#define PKT_BUFFER_LEN 1526

struct virtif_user {
	struct virtif_sc *viu_virtifsc;
};

int
VIFHYPER_MAC(uint8_t **enaddr)
{
	char *enaddrstr;
	struct ether_addr *e_addr;

	enaddrstr = solo5_net_mac_str();
	e_addr = ether_aton(enaddrstr);
	if (e_addr == NULL)
		return 1;
	*enaddr = e_addr->ether_addr_octet;
	return 0;
}

int
VIFHYPER_CREATE(const char *devstr, struct virtif_sc *vif_sc, uint8_t *enaddr,
	struct virtif_user **viup)
{
	struct virtif_user *viu = NULL;

	viu = bmk_memalloc(sizeof(*viu), 0, BMK_MEMWHO_RUMPKERN);
	if (viu == NULL) {
		solo5_console_write("create  fail\n",13);
		solo5_exit();
	}

	viu->viu_virtifsc = vif_sc;

	*viup = viu;
	return 0;
}

void
VIFHYPER_RECEIVE(void)
{
	struct iovec iov[1];
	int len = PKT_BUFFER_LEN;

	uint8_t *data = bmk_memalloc(PKT_BUFFER_LEN, 0, BMK_MEMWHO_RUMPKERN);
	if (data == NULL) {
		solo5_console_write("malloc fail\n",13);
		solo5_exit();
	}

	// XXX shouldn't abort if error
	if (solo5_net_read_sync(data, &len) != 0) {
		solo5_console_write("receive fail\n",13);
		bmk_memfree(data, BMK_MEMWHO_RUMPKERN);
		solo5_exit();
	}

	iov[0].iov_base = data;
	iov[0].iov_len = len;

	VIF_DELIVERPKT(iov, 1);

	bmk_memfree(data, BMK_MEMWHO_RUMPKERN);
}

void
VIFHYPER_SEND(struct virtif_user *viu,
	struct iovec *iov, size_t iovlen)
{
	size_t tlen, i;
	int nlocks;
	void *d;
	char *d0;

	rumpkern_unsched(&nlocks, NULL);
	/*
	 * ukvm doesn't do scatter-gather, so just simply
	 * copy the data into one lump here.  drop packet if we
	 * can't allocate temp memory space.
	 */
	if (iovlen == 1) {
		d = iov->iov_base;
		tlen = iov->iov_len;
	} else {
		for (i = 0, tlen = 0; i < iovlen; i++) {
			tlen += iov[i].iov_len;
		}

		/*
		 * allocate the temp space from RUMPKERN instead of BMK
		 * since there are no huge repercussions if we fail or
		 * succeed.
		 */
		d = d0 = bmk_memalloc(tlen, 0, BMK_MEMWHO_RUMPKERN);
		if (d == NULL)
			goto out;

		for (i = 0; i < iovlen; i++) {
			bmk_memcpy(d0, iov[i].iov_base, iov[i].iov_len);
			d0 += iov[i].iov_len;
		}
	}

	// XXX: check for error
	solo5_net_write_sync(d, tlen);

	if (iovlen != 1)
		bmk_memfree(d, BMK_MEMWHO_RUMPKERN);

out:
	rumpkern_sched(nlocks, NULL);
	return;
}
#endif
