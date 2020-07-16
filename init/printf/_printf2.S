//#include <asm/unistd.h>

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
	leal	36(%esp),%edx		// pointer to format
	movl	(%edx),%esi
	enter	$MSGLEN,$0
	movl	%esp,%edi
	cld

.Lnextfmt:

.Lcopyloop:
	lodsb
	or	%al,%al
	jnz	.Lnowrite

	movl	%edi,%edx
	subl	%esp,%edx
	movl	%esp,%ecx
	xorl	%ebx,%ebx
	incl	%ebx
	push	$4			//__NR_write
	popl	%eax
	int	$0x80
	leave	
	popal
	ret

.Lnowrite:
	cmpb	$'%',%al
	jz	.Lformat
	stosb
	jmp	.Lcopyloop

.Lformat:
	addl	$4,%edx
	movl	(%edx),%ebx

	lodsb
	cmpb	$'s',%al
	jz	stringfmt

/*
 *  format %i
 */
intfmt:
	pushl	%edx
	movl	$0x3b9aca00,%ecx
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
	subl	%ecx,%ebx
	jz	.Lint6
	jnl	.Lint3
	decl	%eax
	addl	%ecx,%ebx

	xchg	%eax,%ecx
	cdq				// %edx:%eax <-- sign extend %eax
	push	$10
	divl	(%esp),%eax		// %eax = quotient, %edx = remainder (0)
	popfl				// discard $10
	xchg	%eax,%ecx

	decl	%eax			// 0 ==> -1 and SF = 1
	js	.Lint2			// SF = 1 ?
	addb	$'1',%al
	jmp	.Lint1

.Lint6:
	addb	$'0',%al
	stosb
	popl	%edx
	jmp	.Lnextfmt

/*
 *  format %s
 */
stringfmt:
.Lstrcpy:
	movb	(%ebx),%al
	incl	%ebx
	stosb
	or	%al,%al
	jnz	.Lstrcpy
.Lstrret:
	decl	%edi
	jmp	.Lnextfmt
