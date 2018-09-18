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
 
    if (dr == NULL)  // opendir returns NULL if couldn't open directory
    {
        printf("Could not open directory" );
        return 0;
    }
 
    while ((de = readdir(dr)) != NULL)
            printf("%s\n", de->d_name);
 
    closedir(dr);    
    return 0;
}

int main(int argc , char *argv[])
{
	int i = 1;
	int n;
	int f;
	char buf[80];

	char cwd[1024];
	if (getcwd(cwd, sizeof(cwd)) != NULL)
		fprintf(stdout, "Current working dir: %s\n", cwd);
	else
		perror("getcwd() error");

	list_dirs("/");

	f = open("/tmp/bla", O_CREAT|O_RDWR);
	assert(f != -1);
	write(f, "123\n", 4);
	lseek(f, 0, SEEK_SET);
	n = read(f, buf, 4);
	assert(n == 4);
	write(1, buf, 4);
	close(f);

	list_dirs("/tmp");
	list_dirs("/dev");

	f = open("/dev/urandom", O_RDONLY);
	assert(f != -1);
	n=read(f,buf,8);
	write(1,buf,n);
	close(f);

	return 0;
}
