#include <stdio.h>
#include <unistd.h>
#include <sys/time.h>
#include <time.h>

int
main()
{
	struct timeval tv0, tv1;
	time_t t0, t1;
	//time_t time(time_t *tloc);

	t0 = time(NULL);
	gettimeofday(&tv0, 0);
	printf("Hello, Rumprun ... I'm feeling tired\n");

	while (1) {
		//sleep(2);

		gettimeofday(&tv1, 0);
		t1 = time(NULL);

		//long elapsed = (tv1.tv_sec-tv0.tv_sec)*1000000 + tv1.tv_usec-tv0.tv_usec;
		time_t elapsed = t1 - t0;
		if (elapsed > 0)
			printf("much better! %ld %ld\n", elapsed, time(NULL));
	}

	return 0;
}
