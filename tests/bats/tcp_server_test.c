#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <err.h>

int main(int argc, char *argv[])
{
	int listenfd = 0, connfd = 0;
	struct sockaddr_in serv_addr;
	int ret;

	listenfd = socket(AF_INET, SOCK_STREAM, 0);
	if (listenfd == -1)
		err(1, "socket() failed");
	memset(&serv_addr, '0', sizeof(serv_addr));

	serv_addr.sin_family = AF_INET;
	serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	serv_addr.sin_port = htons(5000); 

	int optval = 1;
	ret = setsockopt(listenfd, SOL_SOCKET, SO_REUSEPORT, &optval, sizeof(optval));
	if (ret == -1)
		err(1, "setsockopt() failed");

	ret = bind(listenfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr));
	if (ret == -1)
		err(1, "bind() failed");

	ret = listen(listenfd, 10);
	if (ret == -1)
		err(1, "listen() failed");

	connfd = accept(listenfd, (struct sockaddr*)NULL, NULL); 
	if (connfd == -1)
		err(1, "accetp() failed");

	ret = write(connfd, "nabla\n", strlen("nabla\n"));
	if (ret != strlen("nabla\n"))
		err(1, "write() failed");

	close(connfd);
}
