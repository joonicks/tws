#include <asm/unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <asm/signal.h>
#include <sys/time.h>
#include <asm/fcntl.h>

pid_t waitpid(pid_t, int *, int);
pid_t runit(const char *, int);
int sethostname(const char *, size_t);
int setdomainname(const char *, size_t);
int kill(pid_t, int);
int open(const char *, int);
int close(int);
int pause(void);
int chdir(const char *);
ssize_t read(int, void *, size_t);
ssize_t write(int, const void *, size_t);
void (*signal(int, void (*)(int)))(int);
void exit(int) __attribute__(( __noreturn__ ));
void chop(char *);
void printf(const char *, ...);

extern char str_confpath[];
extern char str_rootdir[];
extern char str_devnull[];

extern char str_term;
extern char str_hostname;
extern char str_domainname;
extern char str_spawn;
extern int system_halt;

#define MSGLEN		512
#define MAXCOMLEN	512
#define MAXOPTLEN	32
#define MAXARG		8
#define MAXENV		8
#define MAXSPAWNS	8

void atomic_optget(const char *opt, char *buffer, int bufsize)
{
	int	n,fd;

	chdir(str_confpath);
	fd = open(opt,O_RDONLY);
	chdir(str_rootdir);

	if (fd < 0)
	{
		*buffer = 0;
		return;
	}

	n = read(fd,buffer,bufsize-1);
	buffer[n] = 0;
	chop(buffer);	/* remove \n and anything after */
	close(fd);
}

void sigterm(int sig)
{
	system_halt = 1;
	signal(SIGTERM,sigterm);
}

void sigchld(int sig)
{
redo:
	if ((waitpid(-1,NULL,WNOHANG)) > 0)
		goto redo;
	signal(SIGCHLD,sigchld);
}

int main(char *) __attribute__(( __noreturn__ ));
int main(char *runarg)
{
	/*
	 *  sethostname and setdomainname
	 */
	{
		char	name[128];
		char	*p;

		atomic_optget(&str_hostname,name,sizeof(name));
		if (name[0])
		{
			for(p=name;*p;p++)
				;
			sethostname(name,p-name);
		}
		atomic_optget(&str_domainname,name,sizeof(name));
		if (name[0])
		{
			for(p=name;*p;p++)
				;
			setdomainname(name,p-name);
		}
	}

	/*
	 *  figure out what to run
	 */
	{
		char	buf[MAXCOMLEN];

		atomic_optget(runarg,buf,sizeof(buf));
		if (buf[0])
			runit(buf,1);
	}
	/*
	 *  major kludge-alert
	 *  and no, this is not an entry for the obfuscated C contest...
	 *  (atleast not intended as such)
	 */
	{
		struct	respawn
		{
		pid_t	pid;
		char	run[MAXOPTLEN];
		} spawn[MAXSPAWNS];
		int	x,ret;

		for(x=0;x<MAXSPAWNS;x++)
			spawn[x].pid = 1;

		/*
		 *  read a list of spawns
		 */
		{
			char	buf[MAXCOMLEN];
			char	*dest,*src;

			atomic_optget(&str_spawn,buf,sizeof(buf));
			if (buf[0])
			{
				x = 0;
				src = buf;
			nextspawn:
				dest = spawn[x].run;
				spawn[x].pid = -2;
				while(*src && *src != ' ')
				{
					*(dest++) = *(src++);
				}
				*dest = 0;
				if (*src == ' ')
				{
					x++;
					while(*src == ' ')
						src++;
					if (*src && (x < MAXSPAWNS))
						goto nextspawn;
				}
			}
		}
		/*
		 *  this is where we handle respawns and such...
		 */
loop:
		/*
		 *  make sure everything is running
		 */
		for(x=0;x<MAXSPAWNS;x++)
		{
			ret = kill(spawn[x].pid,0);
			if (ret < 0)
			{
				char	buf[MAXCOMLEN];

				atomic_optget(spawn[x].run,buf,sizeof(buf));
				if (buf[0])
				{
					spawn[x].pid = runit(buf,0);
				}
			}
		}
		system_halt = 0;
		pause();		/* wait for SIGCHLD, SIGTERM */
		/*
		 *  system_halt is set by sigterm()
		 */
		if (system_halt)
		{
			char	buf[MAXCOMLEN];

			/*
			 *  ignore SIGTERM while we're in the shutdown procedure
			 */
			signal(SIGTERM,SIG_IGN);
			atomic_optget(&str_term,buf,sizeof(buf));
			runit(buf,0);
			while(1)
			{
				pause();
			}
			/* not reached */
		}
		goto loop;
	}
}
