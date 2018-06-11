#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <assert.h>

extern char **environ;

int main(int argc , char *argv[])
{
	int i = 1;
	char *s = *environ;

	for (; s; i++) {
		printf("%s\n", s);
		s = *(environ+i);
	}

	char cwd[1024];
	if (getcwd(cwd, sizeof(cwd)) != NULL)
		fprintf(stdout, "Current working dir: %s\n", cwd);
	else
		perror("getcwd() error");
	return 0;


	return 0;
}
