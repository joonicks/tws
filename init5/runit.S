#include <asm/unistd.h>

.global runit
.type	runit,@function
runit:
	xorl	%edx,%edx		// aahhh.. the joy of having a dedicated zero register
	/*
	 *  fork()
	 */
	push	$__NR_fork
	popl	%eax
	int	$0x80
	/*
	 *  am I the child?
	 */
	testl	%eax,%eax
	jz	.Lchild
	/*
	 *  is there an error?
	 */
	cmpl	$-126,%eax
	ja	.Lreturn_error
	/*
	 *  to wait or not to wait, that is ... slow
	 */
	cmpl	%edx,8(%esp)
	jz	.Lreturn
	push	%edx
	push	%edx
	push	%eax			// backup child pid
	call	waitpid
	popl	%eax			// restore child pid
	popl	%edx
	popl	%edx
.Lreturn:
	ret

.Lreturn_error:
	xorl	%eax,%eax
	incl	%eax
	ret

	/*
	 *  I am the child, I am happy, I want to run something!
	 */
.Lchild:
	movl	4(%esp),%eax
	push	%edx
	jmp	.Lspac3

.Lmainloop:
	movb	(%eax),%cl
	cmpb	$32,%cl			// space
	je	.Lspace
	testb	%cl,%cl
	jz	.Lendofstring
	incl	%eax
	jmp	.Lmainloop

.Lspace:
	movb	%dl,(%eax)		// %edx = dedicated zero (0)
.Lspac2:
	incl	%eax
.Lspac3:
	movb	(%eax),%cl
	cmpb	$32,%cl			// space
	je	.Lspac2
	testb	%cl,%cl
	jz	.Lendofstring

	push	%eax
	jmp	.Lmainloop

.Lendofstring:
	movl	%esp,%ecx
	push	%edx			// %edx = dedicated zero (0)

.Lmakeargv:
	movl	(%ecx),%eax
	testl	%eax,%eax
	jz	.Lexe

	push	%eax
	addl	$4,%ecx
	jmp	.Lmakeargv

.Lexe:
	/* xorl %edx,%edx */		/* up there somewhere in the clouds, it has already been done */
	leal	4(%esp),%ecx
	movl	(%esp),%ebx
	push	$__NR_execve
	popl	%eax
	int	$0x80			// int execve (const char *filename, char *const argv [], char *const envp[]);

.Lexit:
	movl	%eax,%ebx
	negl	%ebx
	xorl	%eax,%eax
	incl	%eax
	int	$0x80			// exit

.size	runit,.-runit

