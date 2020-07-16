#include <asm/unistd.h>

.global _start
_start:
	popl	%ecx			// argc
	movl	%esp,%eax		// (char**)argv
	leal	4(%esp,%ecx,4),%ebx	// (char**)envp
	pushl	%ebx
	pushl	%eax
	pushl	%ecx
	call	main
	// noreturn

.global killnum
killnum:
	xorl	%eax,%eax
	movl	4(%esp),%ecx
	jecxz	.Lexit
.Loop:
	movzbl	(%ecx),%edx
	or	%ebx,%ebx
	jz	.Lexit
	cmpb	$'-',%dl
	jz	.Lnext
	cmpb	$0x39,%dl
	ja	.Lexit
	subb	$'0',%dl
	jb	.Lexit
	leal	(%eax,%eax,4),%eax
	addl	%eax,%eax
	addl	%edx,%eax
.Lnext:
	incl	%ecx
	jmp	.Loop
.Lexit:
	ret

.global getppid
getppid:
	push	$__NR_getppid
	jmp	.Lkern3

.global getpid
getpid:
	push	$__NR_getpid
	jmp	.Lkern3

.global getpgid
getpgid:
	xorl	%eax,%eax
	movb	$__NR_getpgid,%al
	jmp	.Lkern4

.global kill
kill:
	push	$__NR_kill
	jmp	.Lkern3

.global write
write:
	push	$__NR_write

.Lkern3:
	popl	%eax
.Lkern4:
	pushl	%ebx
	movl	16(%esp),%edx
	movl	12(%esp),%ecx
	movl	8(%esp),%ebx
	int	$0x80
	popl	%ebx
	ret

.global	exit
exit:
	popl	%eax		// discard
	popl	%ebx		// exit arg
	xorl	%eax,%eax
	incl	%eax
	int	$0x80
	// if we return from exit we might aswell do an uncontrolled crash

.global fmt1
fmt1:
	.string	"killall5(-%i): "
	.byte	0

.global fmt2
fmt2:
	.string	"%i "
	.byte	0

.global fmt3
fmt3:
	.string	"\r\n"
	.byte	0

