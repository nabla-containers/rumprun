#include <hw/machine/md.h>

#ifndef _LOCORE

void cons_init(void);
void cons_putc(int);
void cons_puts(const char *);

#endif /* _LOCORE */

#include <bmk-core/errno.h>
