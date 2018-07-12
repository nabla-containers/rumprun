#include "unistd.h"
int write1(int fd, void* data, int nbytes)
{
    int ret;
    // 1 ==  SYS_write
    asm volatile(
        "syscall" : "=a" (ret) : "0"(1), "D"(fd), "S"(data), "d"(nbytes));
    return ret;
}


int get_pid()
{
    int ret;
    // 39 ==  SYS_getpid
    asm volatile("syscall" : "=a" (ret) : "0"(39) );
    return ret;
}

void digit_to_char(int num)
{
    char chr = 48 + num;
    write1(1, &chr, 1);
}

void digits_to_char(int num)
{
    if(num < 10)
    {
        digit_to_char(num);
    }
    else
    {
        digits_to_char(num/10);
        digit_to_char(num%10);
    }
}

int main()
{
    int ret = 0;
    int pid = 0;
    
    write1(1, "hello world\n", 13);

    pid = getpid();     //libc; uses rumprun syscall handler
    digits_to_char(pid);
    
    write1(1, "\n", 1);
    
    pid = get_pid();
    digits_to_char(pid);
    
    return 0;
}
