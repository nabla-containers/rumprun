#include <stdio.h>
#include <unistd.h>
#include <sys/time.h>

int
main()
{
	struct timeval tv0, tv1;

	gettimeofday(&tv0, 0);
	printf("Hello, Rumprun ... I'm feeling tired\n");

	while (1) {
		//sleep(2);

		gettimeofday(&tv1, 0);

		long elapsed = (tv1.tv_sec-tv0.tv_sec)*1000000 + tv1.tv_usec-tv0.tv_usec;
		if (elapsed > 0)
			printf("much better! %ld\n", elapsed);
	}

	return 0;
}
