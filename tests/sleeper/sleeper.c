#include <stdio.h>
#include <unistd.h>
#include <sys/time.h>

int main() {
	for (;;)
		sleep(0xffffffff);
	return 0;
}
