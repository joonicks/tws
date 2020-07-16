/*
 *  minimal printf
 */
#define	MSGLEN	512

.global	printf
printf:
.global	Printf
Printf:
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
	jnz	.Lstore

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
	movb	$-4,%al
	neg	%ebx
	jnle	.Lminus
	neg	%ebx
.Lmain:
	xchgl	%eax,%ebx		// short for `movl %ebx,%eax'
	cdq				// %edx:%eax <-- sign extend %eax
	divl	%ecx,%eax		// %eax = N, %edx = remain
	movl	%edx,%ebx		// store new number
	addl	%ecx,%eax
	cdq
	push	$10
	popl	%ecx
	divl	%ecx,%eax		// %eax = new %ecx, %edx = N
	xchgl	%eax,%ecx
	xchgl	%eax,%edx

	decl	%eax			// 0 ==> -1 and SF = 1
	js	.Lnominus		// SF = 1 ?
.Lminus:
	addb	$'1',%al
	stosb
.Lnominus:
	incl	%ecx
	loop	.Lmain
	popl	%edx
	decl	%edi
	decl	%eax
.Lstore:
	stosb
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
