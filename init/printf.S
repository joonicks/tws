/*
 *  minimal printf
 */
#define	MSGLEN	512

.global	printf
.type	printf,@function
printf:
	pushal				// push 8x4 bytes = 32 bytes
	leal	36(%esp),%edx		// pointer to format
	movl	(%edx),%esi		// src = format
	enter	$MSGLEN,$0		// buffer[MSGLEN]
	movl	%esp,%edi		// dest = buffer
	cld

.Lnextfmt:
.Lcopyloop:
	lodsb				// al = *(src++)
	or	%al,%al			// al == 0 ?
	jnz	.Lnowrite

	movl	%edi,%edx		// dest
	subl	%esp,%edx		// dest - &buffer[] = length
	movl	%esp,%ecx		// &buffer[]
	xorl	%ebx,%ebx
	incl	%ebx			// 1 --> stdout
	push	$4			// 4 --> __NR_write
	popl	%eax
	int	$0x80			// write(1,buffer,length)
	leave				// undo buffer, local vars (ebp --> esp)
	popal
	ret

.Lnowrite:
	stosb
	cmpb	$'%',%al
	jnz	.Lnextfmt
	decl	%edi

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
	pushl	%ebp
	pushl	%edx
	xorl	%ebp,%ebp
	movl	$0x3b9aca00,%ecx
	movb	$'-',%al
	neg	%ebx
	jnle	.Lsign
	neg	%ebx
.Lmain:
	xchgl	%eax,%ebx		// short for `movl %ebx,%eax'
	cdq				// %edx:%eax <-- sign extend %eax
	divl	%ecx,%eax		// %eax = N, %edx = rest
	movl	%edx,%ebx		// save rest
	decl	%ecx
	jecxz	.Lnum
/*
	leal	1(%ecx,%eax),%ecx
*/
	incl	%ecx
	addl	%ecx,%eax
	cdq
	push	$10
	popl	%ecx
	divl	%ecx,%eax		// %eax = new %ecx, %edx = N
	xchgl	%eax,%ecx
	xchgl	%eax,%edx
	addl	%ebp,%eax
	jz	.Lskip
.Lnum:
	or	$0x30,%ebp
	or	%ebp,%eax
.Lsign:
	stosb
.Lskip:
	incl	%ecx
	loop	.Lmain
	popl	%edx
	popl	%ebp
	jmp	.Lnextfmt

/*
 *  format %s
 */
stringfmt:
.Lstrcpy:
	movb	(%ebx),%al
	or	%al,%al
	jz	.Lnextfmt
	incl	%ebx
	stosb
	jmp	.Lstrcpy

.size	printf,.-printf
