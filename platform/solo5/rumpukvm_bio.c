/*-
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

#include <bmk-core/errno.h>
#include <bmk-core/memalloc.h>
#include <bmk-core/printf.h>
#include <bmk-core/sched.h>
#include <bmk-core/string.h>

#include <bmk-rumpuser/core_types.h>
#include <bmk-rumpuser/rumpuser.h>

#define NBLKDEV 10
#define BLKFDOFF 64

#include <solo5.h>

#define XENBLK_MAGIC "XENBLK_"

static int sector_size = 512;


/* not really bio-specific, but only touches this file for now */
int
rumprun_platform_rumpuser_init(void)
{
	return 0;
}


static int
devname2num(const char *name)
{
	return 0;
}

int
rumpuser_open(const char *name, int mode, int *fdp)
{
        struct solo5_block_info bi;
	int num;

	if (bmk_strncmp(name, XENBLK_MAGIC, sizeof(XENBLK_MAGIC)-1) != 0)
		return -1;
	if ((mode & RUMPUSER_OPEN_BIO) == 0 || (num = devname2num(name)) == -1)
		return BMK_ENXIO;

        solo5_block_info(&bi);
	sector_size = bi.block_size;
	*fdp = BLKFDOFF + num;
	return 0;
}

int
rumpuser_close(int fd)
{
	return 0;
}

int
rumpuser_getfileinfo(const char *name, uint64_t *size, int *type)
{
        struct solo5_block_info bi;
	int num;

	if (bmk_strncmp(name, XENBLK_MAGIC, sizeof(XENBLK_MAGIC)-1) != 0)
		return -1;
	if ((num = devname2num(name)) == -1)
		return BMK_ENXIO;

        solo5_block_info(&bi);
        *size = bi.capacity;
	*type = RUMPUSER_FT_BLK;

	return 0;
}


void
rumpuser_bio(int fd, int op, void *data, size_t dlen, int64_t off,
	rump_biodone_fn biodone, void *donearg)
{
	int len = (int)dlen;
	int ret;

	if (op & RUMPUSER_BIO_READ)
		ret = solo5_block_read((uint64_t)off, data, len);
	else
		ret = solo5_block_write((uint64_t)off, data, len);

	if (ret == 0)
		biodone(donearg, len, 0);
	else
		biodone(donearg, 0, BMK_EIO);
}
