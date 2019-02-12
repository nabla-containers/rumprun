#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <assert.h>
#include <dirent.h>
#include <unistd.h>
#include <string.h>

#define RENAMES 25

char strs[100][100] = {
"aRjKN", "Bt", "HNP", "Y", "vPB", "pglklhZdi", "x8f16o", "uB57R1Rjag", "jP", "HvXKQsD", "pFiWPa7", "aAkWzD99", "9KNXv", "mY3wVh1jt7", "gc53", "Y", "tn7gsmyg", "Q", "CMnh18LK", "WZg", "QAc", "f", "qC", "HheKnC", "bQ", "TaL9D2BT", "6hYG4", "jZFpMjh9c", "it8", "1JKq5SP", "c93sOztr", "Qc6ZFk", "E2", "qtN4X6r", "YFGPe", "POzSs", "k6P", "nn3w63GCrM", "gqEIu", "Y", "YEcaqd7OGn", "wtPa7DJ1q1", "sXRhZ", "Cax1CCNv", "FnixUtR", "O", "4VIGg", "UqTvImHBFb", "P", "w", "vxjG", "b66E8", "5", "xPa5d", "P01kVGRJuW", "9jAo", "ze93oj", "K", "YLaGCb", "DEZXCh1DnF", "j0CpDf02z", "bohNNlO", "tYzza9VPrx", "ZvnMZkxE6n", "ez", "1y6ES", "evu", "Hl", "x0rkyOmz", "s6sjad", "D8aNJ", "w8ZJOxPL1", "AMcLEJ", "TGZDZk0z", "n2Q", "UiO", "B", "7fO", "Um5iGKGIU", "BZsb", "XkY", "HV1awNeiKr", "jZ", "wvo", "SnxMuR4vN", "Mv2J8KuQv", "ZHN", "KL3e", "K8", "BU53F", "kgp", "YpMsg", "SGavgQGw", "58yDLwZI", "Fm07kxl5", "NTHJ", "4d", "ytC0rXW", "H2", "2CsFsi",
};

int main(int argc , char *argv[])
{
	int ret;
	int i;
	int f;
	char path1[256];
	char path2[256];
	char *base;
	char sufix[] = "lzma.cpython-35.pyc";

	if (argc > 1)
		base = argv[1];
	else
		base = "/test/lib/python3.5/__pycache__";

	// appends
	for (i = 0; i < RENAMES; i++) {
		memset(path1, 0, 256);
		sprintf(path1, "%s/%s%s.43307160", base, strs[i], sufix);
		printf("creating %s\n", path1);
		f = open(path1, O_RDWR|O_CREAT|O_APPEND, 0777);
		ret = write(f, "a", 1);
		close(f);
	}

	// renames
	for (i = 0; i < RENAMES; i++) {
		memset(path1, 0, 256);
		memset(path2, 0, 256);
		sprintf(path1, "%s/%s%s.43307160", base, strs[i], sufix);
		sprintf(path2, "%s/%s%s", base, strs[i], sufix);
		printf("renanimg %s -> %s\n", path1, path2);
		ret = rename(path1, path2);
		if (ret != 0)
			perror("rename");
	}

	// renames back
	for (i = 0; i < RENAMES; i++) {
		memset(path1, 0, 256);
		memset(path2, 0, 256);
		sprintf(path1, "%s/%s%s", base, strs[i], sufix);
		sprintf(path2, "%s/%s%s.43307160", base, strs[i], sufix);
		printf("renanimg %s -> %s\n", path1, path2);
		ret = rename(path1, path2);
		if (ret != 0)
			perror("rename");
	}

	// renames
	for (i = 0; i < RENAMES; i++) {
		memset(path1, 0, 256);
		memset(path2, 0, 256);
		sprintf(path1, "%s/%s%s.43307160", base, strs[i], sufix);
		sprintf(path2, "%s/%s%s", base, strs[i], sufix);
		printf("renanimg %s -> %s\n", path1, path2);
		ret = rename(path1, path2);
		if (ret != 0)
			perror("rename");
	}

	// renames back
	for (i = 0; i < RENAMES; i++) {
		memset(path1, 0, 256);
		memset(path2, 0, 256);
		sprintf(path1, "%s/%s%s", base, strs[i], sufix);
		sprintf(path2, "%s/%s%s.43307160", base, strs[i], sufix);
		ret = rename(path1, path2);
		if (ret != 0)
			perror("rename");
	}

	sync();
}
