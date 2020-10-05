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

#define SOLO5_BLK_NAME "rootfs"

static solo5_handle_t blk_handle = 0;
static struct solo5_block_info blk_info;

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
	solo5_result_t ret;
	int num;

	if (bmk_strncmp(name, XENBLK_MAGIC, sizeof(XENBLK_MAGIC)-1) != 0)
		return -1;
	if ((mode & RUMPUSER_OPEN_BIO) == 0 || (num = devname2num(name)) == -1)
		return BMK_ENXIO;

	if (blk_handle == 0) {
		ret = solo5_block_acquire(SOLO5_BLK_NAME, &blk_handle, &blk_info);
		if (ret != SOLO5_R_OK)
			return -1;
	}
	sector_size = blk_info.block_size;
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
	solo5_result_t ret;
	int num;

	if (bmk_strncmp(name, XENBLK_MAGIC, sizeof(XENBLK_MAGIC)-1) != 0)
		return -1;
	if ((num = devname2num(name)) == -1)
		return BMK_ENXIO;

	if (blk_handle == 0) {
		ret = solo5_block_acquire(SOLO5_BLK_NAME, &blk_handle, &blk_info);
		if (ret != SOLO5_R_OK)
			return -1;
	}
	*size = blk_info.capacity;
	*type = RUMPUSER_FT_BLK;

	return 0;
}


void
rumpuser_bio(int fd, int op, void *data, size_t dlen, int64_t off,
	rump_biodone_fn biodone, void *donearg)
{
	solo5_result_t ret;
	int len = (int)dlen;
	uint64_t curr_off;
	uint64_t d = (uint64_t)data;

	if (len % sector_size != 0 || len == 0) {
		biodone(donearg, 0, BMK_EIO);
		return;
	}

	if (blk_handle == 0) {
		ret = solo5_block_acquire(SOLO5_BLK_NAME, &blk_handle, &blk_info);
		if (ret != SOLO5_R_OK)
			return;
    }

	for (curr_off = off; len > 0; curr_off += sector_size,
					len -= sector_size,
					d += sector_size) {
		if (op & RUMPUSER_BIO_READ)
			ret = solo5_block_read(blk_handle, curr_off,
						(void *)d, sector_size);
		else
			ret = solo5_block_write(blk_handle, curr_off,
						(void *)d, sector_size);
		if (ret != SOLO5_R_OK) {
			biodone(donearg, curr_off - off, BMK_EIO);
			return;
		}
	}

	biodone(donearg, dlen, 0);
}
