#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <assert.h>

int main(int argc , char *argv[])
{
	int l, n;
	int f = open("/test/aaaaaaaaaaaaaaax", O_RDONLY);
	while ((n=read(f,l,80)) > 0)
		write(1,l,n);
	close(f);

	f = open("/test/bla", O_CREAT|O_WRONLY);
	assert(f != -1);
	write(f, "bla\n", 4);
	close(f);

	f = open("/test/bla", O_RDONLY);
	assert(f != -1);
	while ((n=read(f,l,80)) > 0)
		write(1,l,n);

	return 0;
}
