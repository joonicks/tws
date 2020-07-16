#include <asm/unistd.h>

/*
 *  minimal printf
 */
// void printf(const char *format, ...)
#define	MSGLEN	512

.global	Printf
.global	printf
Printf:
printf:
	pushal				// push 8x4 bytes = 32 bytes
	movl	36(%esp),%esi		// 32 + 4 (return) = 36
	leal	40(%esp),%edx		// pointer to args
	enter	$MSGLEN,$0
	movl	%esp,%edi
	cld

.Lcopyloop:
	lodsb
	or	%al,%al
	jz	.Lwrite
	cmpb	$'%',%al
	jz	.Lformat
.Ldocopy:
	stosb
	jmp	.Lcopyloop

.Lwrite:
	movl	%edi,%edx
	subl	%esp,%edx
	movl	%esp,%ecx
	xorl	%ebx,%ebx
	incl	%ebx
	push	$__NR_write
	popl	%eax
	int	$0x80
	leave	
	popal
	ret

.Lformat:
	lodsb
	cmpb	$'s',%al
	jz	.Lstring
//	cmpb	$'i',%al
//	jz	.Lint

/*
 *  format %i
 */
.Lint:
	leal	num,%ecx
	movl	(%edx),%ebx
	addl	$4,%edx
	bt	$31,%ebx
	jnc	.Lint2
	neg	%ebx
	movb	$'-',%al
.Lint1:
	stosb
.Lint2:
	xorl	%eax,%eax
.Lint3:
	incl	%eax
	subl	(%ecx),%ebx
	jnl	.Lint3
	decl	%eax
	addl	(%ecx),%ebx
	or	%ebx,%ebx
	jz	.Lint6
	addl	$4,%ecx
	or	%al,%al
	jz	.Lint3
.Lint5:
	addb	$'0',%al
	jmp	.Lint1

.Lint6:
	addb	$'0',%al
	jmp	.Ldocopy

/*
 *  format %s
 */
.Lstring:
	pushl	%esi
	movl	(%edx),%esi
	addl	$4,%edx
.Lstrcpy:
	lodsb
	stosb
	or	%al,%al
	jnz	.Lstrcpy
.Lstrret:
	decl	%edi
	popl	%esi
	jmp	.Lcopyloop


.global num
num:
	.long	0x3b9aca00, 0x05f5e100, 0x00989680, 0x000f4240, 0x000186a0
	.long	0x00002710, 0x000003e8, 0x00000064, 0x0000000a, 0x00000001
