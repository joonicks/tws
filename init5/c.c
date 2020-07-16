#include <asm/unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <asm/signal.h>
#include <sys/time.h>
#include <asm/fcntl.h>

pid_t waitpid(pid_t, int *, int);
pid_t fork(void);
int execve(const char *, char *const [], char *const []) __attribute__(( __noreturn__ ));
int sethostname(const char *, size_t);
int setdomainname(const char *, size_t);
int kill(pid_t, int);
int open(const char *, int);
int close(int);
int pause(void);
int killnum(const char *);
ssize_t read(int, void *, size_t);
ssize_t write(int, const void *, size_t);
void (*signal(int, void (*)(int)))(int);
void exit(int) __attribute__(( __noreturn__ ));
void chop(char *);
void printf(const char *, ...);

int	foobaz = 1;

int main(int argc, char **argv, char **envp) __attribute__(( __noreturn__ ));
int main(int argc, char **argv, char **envp)
{
	int	sig;

	sig = killnum(argv[1]);
	printf("(-%i)\n",sig);
	printf("%i\n",9);
	exit(0);
}

