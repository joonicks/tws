#include <asm/unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <asm/signal.h>
#include <sys/time.h>
#include <asm/fcntl.h>

pid_t getpid(void);
pid_t getppid(void);
pid_t getpgid(pid_t);
int execve(const char *, char *const [], char *const []) __attribute__(( __noreturn__ ));
int kill(pid_t, int);
int killnum(const char *);
ssize_t write(int, const void *, size_t);
void exit(int) __attribute__(( __noreturn__ ));
void printf(const char *, ...);

#define MSGLEN		512
#define MAXCOMLEN	512
#define MAXOPTLEN	32
#define MAXARG		8
#define MAXENV		8
#define MAXSPAWNS	8

extern char fmt1;
extern char fmt2;
extern char fmt3;

int main(int argc, char **argv, char **envp) __attribute__(( __noreturn__ ));
int main(int argc, char **argv, char **envp)
{
	pid_t	pid,ppid;
	int	i,ret,sig;

	sig = killnum(argv[1]);
	printf(&fmt1,sig);
	pid = getpid();
	ppid = getppid();
	for(i=2;i<65536;i++)
	{
		ret = getpgid(i);
		if ((ret >= 0) && (i > 1) && (i != pid) && (i != ppid))
		{
			printf(&fmt2,i);
			kill(i,sig);
		}
	}
	write(1,&fmt3,2);
	exit(0);
}
