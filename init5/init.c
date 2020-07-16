#include <unistd.h>
#include <sys/types.h>
#include <signal.h>
#include <fcntl.h>
#include <wait.h>

/*
#include <asm/unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <asm/signal.h>
#include <sys/time.h>
#include <asm/fcntl.h>
*/

pid_t tws_waitpid(pid_t, int *, int);
pid_t tws_runit(const char *, int);
int tws_sethostname(const char *, size_t);
int tws_setdomainname(const char *, size_t);
int tws_kill(pid_t, int);
int tws_open(const char *, int);
int tws_close(int);
int tws_pause(void);
int tws_chdir(const char *);
ssize_t tws_read(int, void *, size_t);
ssize_t tws_write(int, const void *, size_t);
void (*tws_signal(int, void (*)(int)))(int);
void tws_exit(int) __attribute__(( __noreturn__ ));
void tws_chop(char *);
void tws_printf(const char *, ...);

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

	tws_chdir(str_confpath);
	fd = tws_open(opt,O_RDONLY);
	tws_chdir(str_rootdir);

	if (fd < 0)
	{
		*buffer = 0;
		return;
	}

	n = tws_read(fd,buffer,bufsize-1);
	buffer[n] = 0;
	tws_chop(buffer);	/* remove \n and anything after */
	tws_close(fd);
}

void sigterm(int sig)
{
	system_halt = 1;
	tws_signal(SIGTERM,sigterm);
}

void sigchld(int sig)
{
redo:
	if ((tws_waitpid(-1,NULL,WNOHANG)) > 0)
		goto redo;
	tws_signal(SIGCHLD,sigchld);
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
			tws_sethostname(name,p-name);
		}
		atomic_optget(&str_domainname,name,sizeof(name));
		if (name[0])
		{
			for(p=name;*p;p++)
				;
			tws_setdomainname(name,p-name);
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
					spawn[x].pid = tws_runit(buf,0);
				}
			}
		}
		system_halt = 0;
		tws_pause();		/* wait for SIGCHLD, SIGTERM */
		/*
		 *  system_halt is set by sigterm()
		 */
		if (system_halt)
		{
			char	buf[MAXCOMLEN];

			/*
			 *  ignore SIGTERM while we're in the shutdown procedure
			 */
			tws_signal(SIGTERM,SIG_IGN);
			atomic_optget(&str_term,buf,sizeof(buf));
			tws_runit(buf,0);
			while(1)
			{
				tws_pause();
			}
			/* not reached */
		}
		goto loop;
	}
}
