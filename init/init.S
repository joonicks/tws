#include <asm/unistd.h>

.global _start
_start:
	/*
	 *  umask(022), a security thing(tm)
	 */
	push	$022
	popl	%ebx
	push	$__NR_umask
	popl	%eax
	int	$0x80
	/*
	 *  make the code pages writeable so we can store data in them!
	 */
	push	$7			// (PROT_READ|PROT_WRITE|PROT_EXEC)
	popl	%edx
	movl	$_start,%ebx
	movl	$0xfffff000,%ecx
	movl	%esp,%ebp
	andl	%ecx,%ebx
	andl	%ecx,%ebp
	negl	%ecx			// turns 0xfffff000 into 0x1000
	push	$__NR_mprotect
	popl	%eax
	int	$0x80
	/*
	 *  make a stack address ((_start & 0xfffff000) + 0x1000)
	 */
	leal	-1(%ebx,%ecx),%edi
	/*
	 *
	 */
	movl	$str_autoopt,%esi
	popl	%edx			// argc
	decl	%edx
	decl	%edx
	js	.L1			// less than 2 args?
	popl	%edx			// argv[0]
	popl	%edx			// argv[1]
	testl	%edx,%edx
	jz	.L1
	cmpb	$0,(%edx)
	jz	.L1
	movl	%edx,%esi
.L1:
	movl	%esi,%edx		// copy %esi to %edx (backup)
	/*
	 *  copy runarg from the real stack to the new stack
	 */
	cld
.L2:
	decl	%edi
	lodsb
	testb	%al,%al
	jnz	.L2
	/*
	 *  %edi now has room for runarg
	 */
	andl	$-4,%edi		// 4-byte align the stack pointer
	movl	%edi,%esp		// stack switch
	push	%edi			// store address for runarg
	movl	%edx,%esi
.L3:
	lodsb
	stosb
	testb	%al,%al
	jnz	.L3
	/*
	 *  unmap the original stack...
	 */
	movl	$4096,%ecx
	movl	%ebp,%ebx
	push	$__NR_munmap
	popl	%eax
	int	$0x80
	/*
	 *  toss a banner at them
	 */
	push	$bannerfmt		// 1 args pushed
	call	printf
	/*
	 *
	 */
	call	sigchld			// ignores its arguments
	call	sigterm			// ignores its arguments
	/*
	 *
	 */
	push	$0			// 2 args pushed
	call	close
	/*
	 *
	 */
	/* push $0 */			/* O_RDONLY happens to be $0, which we've already pushed */
	push	$str_devnull		// 3 args pushed
	call	open			/* returns 0 */
	push	$str_rootdir		// 4 args pushed
	call	chdir
	/*
	 *  undo all args pushed sofar (4)
	 */
	addl	$(4*4),%esp
	/*
	 *  fall into main()
	 */
	call	main
	/*
	 *  we dont ever return from main()
	 */
.size	_start,.-_start

.global kill
kill:
	push	$__NR_kill
	jmp	.Lkern3

.global sethostname
sethostname:
	push	$__NR_sethostname
	jmp	.Lkern3

.global setdomainname
setdomainname:
	push	$__NR_setdomainname
	jmp	.Lkern3

.global waitpid
waitpid:
	push	$__NR_waitpid
	jmp	.Lkern3

.global read
read:
	push	$__NR_read
	jmp	.Lkern3

.global write
write:
	push	$__NR_write
	jmp	.Lkern3

.global open
open:
	push	$__NR_open
	jmp	.Lkern3

.global close
close:
	push	$__NR_close
	jmp	.Lkern3

.global signal
signal:
	push	$__NR_signal
	/* fall through */

.Lkern3:
	popl	%eax
	pushl	%ebx
	movl	16(%esp),%edx
	movl	12(%esp),%ecx
	movl	8(%esp),%ebx
.LkernZ:
	int	$0x80
	popl	%ebx
	ret

.global chdir
.type	chdir,@function
chdir:
	xchgl	4(%esp),%ebx
	push	$__NR_chdir
	popl	%eax
	int	$0x80
	movl	4(%esp),%ebx
	ret
.size	chdir,.-chdir

.global pause
.type	pause,@function
pause:
	push	$__NR_pause
	popl	%eax
	int	$0x80
	ret
.size	pause,.-pause

.global	exit
.type	exit,@function
exit:
	popl	%ebx		// discard return pointer
	popl	%ebx		// exit arg
	xorl	%eax,%eax
	incl	%eax
	int	$0x80
	/* exit does not return */
.size	exit,.-exit

.global chop
chop:
	movl	4(%esp),%eax
.L10:
	movb	(%eax),%cl
	xorb	$'\n',%cl
	je	.L11
	incl	%eax
	or	%cl,%cl
	jnz	.L10
	ret
.L11:
	movb	%cl,(%eax)
	ret
.size	chop,.-chop

/*
 *
 *  some data to play with
 *
 */

.global str_confpath
.type	str_confpath,@object
str_confpath:
	.ascii	"/etc/init"

.global str_rootdir
.type	str_rootdir,@object
str_rootdir:
	.ascii	"/"
	.byte	0

.global str_devnull
.type	str_devnull,@object
str_devnull:
	.ascii	"/dev/null"
	.byte	0

.global str_autoopt
.type	str_autoopt,@object
str_autoopt:
	.ascii	"auto"
	.byte	0

.global str_spawn
.type	str_spawn,@object
str_spawn:
	.ascii	"spawn"
	.byte	0

.global str_term
.type	str_term,@object
str_term:
	.ascii	"term"
	.byte	0

.global str_hostname
.type	str_hostname,@object
str_hostname:
	.ascii	"hostname"
	.byte	0

.global str_domainname
.type	str_domainname,@object
str_domainname:
	.ascii	"domainname"
	.byte	0

.global	bannerfmt
.type	bannerfmt,@object
bannerfmt:
	.ascii	"INIT: twsinit version 0.3 booting (%s)\n"
	.byte	0

.global system_halt
.type	system_halt,@object
.size	system_halt,4
system_halt:
	.long	0

