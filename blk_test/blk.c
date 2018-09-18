#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <assert.h>
#include <dirent.h>

int list_dirs(char *path)
{
	struct dirent *de;
	DIR *dr = opendir(path);

	if (dr == NULL) { // opendir returns NULL if couldn't open directory
		return 1;
	}

	while ((de = readdir(dr)) != NULL)
		puts(de->d_name);

	closedir(dr);
	return 0;
}

int main(int argc , char *argv[])
{
	int l, n;
	char buf[80];
	int f;
	char name[256];

	if (argc < 2) {
		printf("usage: blk [file|dir]");
	}

	strcpy(name, argv[1]);

	if (list_dirs(name) == 0) {
		return 0;
	}

	// not a directory, print file contents
	f = open(name, O_RDONLY);
	if (f > 0) {
		while ((n=read(f,buf,80)) > 0)
			write(1,buf,n);
		close(f);
	}

	return 0;
}
