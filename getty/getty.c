#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include <unistd.h>
#include <termio.h>
#include <signal.h>
#include <fcntl.h>
#include <utmp.h>
#include <syslog.h>
#include <time.h>

#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/file.h>
#include <sys/param.h>
#include <sys/utsname.h>

#define TERM_SPEED		B38400

extern	char str_issue[];
extern	char str_login[];
extern	char str_term[];
extern	char str_dash[];
extern	char str_lf[];
extern	char str_dev[];
extern	char str_erase[];
extern	char logname[128];
extern	char str_ttyname[];
extern	char prompt[];
extern	int prompt_sz;

struct chardata
{
	int	erase;			/* erase character */
	int	kill;			/* kill character */
	int	eol;			/* end-of-line character */
	int	parity;			/* what parity did we see */
};

/*
 *  asmgetty.S
 */
int tws_close(int);
int tws_dup(int);
int tws_fcntl(int, int, ...);
int tws_ioctl(int, int, ...);
int tws_open(char *, int, ...);
int tws_write(int, const char *, int);
int tws_read(int, char *, int);
time_t tws_time(time_t *);
void tws_execve(const char *, char *const [], char *const []) __attribute__ ((__noreturn__));
void tws_exit(int) __attribute__ ((__noreturn__));
void set_perm_stdio(void);
void tws_readc(char *);
void tws_sleep1(void);

/*
 *  getty.c functions
 */
char *get_logname(struct chardata *, struct termios *);

/* Some shorthands for control characters. */

#define CTL(x)		(x ^ 0100)	/* Assumes ASCII dialect */
#define	CR		CTL('M')	/* carriage return */
#define	NL		CTL('J')	/* line feed */
#define	BS		CTL('H')	/* back space */
#define	DEL		CTL('?')	/* delete */

/* Defaults for line-editing etc. characters; you may want to change this. */

#define DEF_ERASE	DEL		/* default erase character */
#define DEF_INTR	CTL('C')	/* default interrupt character */
#define DEF_QUIT	CTL('\\')	/* default quit char */
#define DEF_KILL	CTL('U')	/* default kill char */
#define DEF_EOF		CTL('D')	/* default EOF char */
#define DEF_EOL		0
#define DEF_SWITCH	0		/* default switch char */

#undef	TCGETA
#undef	TCSETA
#undef	TCSETAW

#define	TCGETA	TCGETS
#define	TCSETA	TCSETS
#define	TCSETAW	TCSETSW

void tws_main(int mypid)
{
	struct	chardata cp;		/* set by get_logname() */
	struct	termios tio;		/* terminal mode bits */
	char	*exec_argv[4];
	char	*exec_envp[2];
	int	fd,n;

	if (tws_open(str_ttyname,O_RDWR|O_NONBLOCK,0) != 0)
		tws_exit(1);

	if (tws_dup(0) != 1 || tws_dup(0) != 2)
		tws_exit(1);

	if (tws_ioctl(0,TCGETA,&tio) < 0)
		tws_exit(1);

	set_perm_stdio();

	tws_ioctl(0,TIOCSPGRP,&mypid);

	/*
	 * Initial termio settings: 8-bit characters, raw-mode, blocking i/o.
	 * Special characters are set after we have read the login name; all
	 * reads will be done in raw mode anyway. Errors will be dealt with
	 * lateron.
	 */

	/* flush input and output queues, important for modems! */
	tws_ioctl(0,TCFLSH,TCIOFLUSH);

	tio.c_cflag = CS8 | HUPCL | CREAD | TERM_SPEED;
	tio.c_iflag = tio.c_lflag = tio.c_oflag = tio.c_line = 0;
	tio.c_cc[VMIN] = 1;
	tio.c_cc[VTIME] = 0;

	/* Optionally enable hardware flow control */
	tws_ioctl(0,TCSETA,&tio);

	/* go to blocking input even in local mode */
	tws_fcntl(0,F_SETFL,tws_fcntl(0,F_GETFL,0) & ~O_NONBLOCK);
	tws_fcntl(1,F_SETFL,tws_fcntl(1,F_GETFL,0) & ~O_NONBLOCK);

	if ((fd = tws_open(str_issue,O_RDONLY)) >= 0)
	{
		for(;;)
		{
			n = tws_read(fd,logname,sizeof(logname));
			if (n <= 0)
				break;
			tws_write(1,logname,n);
		}
		tws_close(fd);
	}

	/* Read the login name. */
	while((exec_argv[2] = get_logname(&cp,&tio)) == 0)
		;

	/* General terminal-independent stuff. */
	tio.c_iflag |= IXON | IXOFF;			/* 2-way flow control */
	tio.c_lflag |= ICANON | ISIG | ECHO | ECHOE | ECHOK| ECHOKE;
	tio.c_oflag |= OPOST;
	tio.c_cc[VINTR] = DEF_INTR;			/* default interrupt */
	tio.c_cc[VQUIT] = DEF_QUIT;			/* default quit */
	tio.c_cc[VEOF] = DEF_EOF;			/* default EOF character */
	tio.c_cc[VEOL] = DEF_EOL;
	tio.c_cc[VSWTC] = DEF_SWITCH;			/* default switch character */

	/* Account for special characters seen in input. */
	if (cp.eol == CR)
	{
		tio.c_iflag |= ICRNL;			/* map CR in input to NL */
		tio.c_oflag |= ONLCR;			/* map NL in output to CR-NL */
	}
	tio.c_cc[VERASE] = cp.erase;			/* set erase character */
	tio.c_cc[VKILL] = cp.kill;			/* set kill character */

	/* Account for the presence or absence of parity bits in input. */
	switch(cp.parity)
	{
	case 0:					/* space (always 0) parity */
		break;
	case 1:					/* odd parity */
		tio.c_cflag |= PARODD;
		/* FALLTHROUGH */
	case 2:					/* even parity */
		tio.c_cflag |= PARENB;
		tio.c_iflag |= INPCK | ISTRIP;
		/* FALLTHROUGH */
	case (1 | 2):				/* no parity bit */
		tio.c_cflag &= ~CSIZE;
		tio.c_cflag |= CS7;
		break;
	}

	if (tws_ioctl(0,TCSETA,&tio) < 0)
		tws_exit(1);

	tws_write(1,str_lf,1);

	exec_argv[0] = str_login;
	exec_argv[1] = str_dash;
	exec_argv[3] = NULL;

	exec_envp[0] = str_term;
	exec_envp[1] = NULL;

	tws_execve(str_login,exec_argv,exec_envp);
}

/*
 *  get_logname - get user name, establish parity, speed, erase, kill, eol
 */
char *get_logname(struct chardata *cp, struct termios *tp)
{
	char	*bp;
	char	c;			/* input character, full eight bits */
	char	ascval;			/* low 7 bits of input character */
	int	bits;			/* # of "1" bits per character */
	int	mask;			/* mask with 1 bit up */

	/* Initialize kill, erase, parity etc. (also after switching speeds). */
	cp->erase = DEF_ERASE;
	cp->kill = DEF_KILL;
	cp->eol = 13;
	cp->parity = 0;

	/* Flush pending input (esp. after parsing or switching the baud rate). */
	tws_sleep1();
	tws_ioctl(0,TCFLSH,TCIFLUSH);

	/* Prompt for and read a login name. */
	*logname = 0;
	while(*logname==0)
	{
		tws_write(1,prompt,prompt_sz);

		/* Read name, watch for break, parity, erase, kill, end-of-line. */
		for(bp=logname,cp->eol=0;cp->eol==0;)
		{
			/* Do not report trivial EINTR/EIO errors. */
			tws_readc(&c);

			/* Do parity bit handling. */
			if (c != (ascval = (c & 0177)))		/* "parity" bit on ? */
			{
				for(bits=1,mask=1;mask&0177;mask<<=1)
				{
					if (mask & ascval)
						bits++;		/* count "1" bits */
				}
				cp->parity |= ((bits & 1) ? 1 : 2);
			}

			/* Do erase, kill and end-of-line processing. */
			switch(ascval)
			{
			case CR:
			case NL:
				*bp = 0;			/* terminate logname */
				cp->eol = ascval;		/* set end-of-line char */
				break;
			case BS:
			case DEL:
			case '#':
				cp->erase = ascval;		/* set erase character */
				if (bp > logname)
				{
					tws_write(1,(str_erase + (cp->parity * 4)),3);
					bp--;
				}
				break;
			case CTL('U'):
			case '@':
				cp->kill = ascval;		/* set kill character */
				while(bp > logname)
				{
					tws_write(1,(str_erase + (cp->parity * 4)),3);
					bp--;
				}
				break;
			case CTL('D'):
				tws_exit(0);
			default:
				if (ascval < 32 || ascval > 126)
				{
					/* ignore garbage characters */ ;
				}
				else
				if (bp - logname >= sizeof(logname) - 1)
				{
					tws_exit(1);
				}
				else
				{
					tws_write(1,&c,1);	/* echo the character */
					*bp++ = ascval;		/* and store it */
				}
				break;
			}
		}
	}
	return(logname);
}
