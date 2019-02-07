#include <stdio.h>
#include <unistd.h>
#include <string.h>

char *expected;

int main(int argc , char *argv[])
{
	char cwd[1024];

	if (argc < 2)
		expected = "/";
	else
		expected = argv[1];

	fprintf(stdout, "Expected working dir: %s\n", expected);

	if (getcwd(cwd, sizeof(cwd)) != NULL) {
		fprintf(stdout, "Current working dir: %s\n", cwd);
		if (strcmp(cwd, expected) != 0) {
			return 1;
		}
	} else {
		perror("getcwd() error");
		return 1;
	}

	return 0;
}
