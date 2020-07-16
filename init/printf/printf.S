/*
 *  Copyright (c) 2000 A Lander. All rights reserved.
 *  No warranty.
 */

/*
 *  minimal printf
 */
#define	MSGLEN	512

.global	printf
printf:
.global	Printf
Printf:
	pushal				// save registers
	leal	36(%esp),%edx		// pusha (32) + return pointer (4) = 36 --> format
	movl	(%edx),%esi		// src = format
	enter	$MSGLEN,$0		// buffer[MSGLEN]
	movl	%esp,%edi		// dest = buffer
	cld

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
	popal				// restore registers
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
	addb	$'1',%al		// compensate for decl
	stosb
.Lnominus:
	incl	%ecx			// compensate for loop
	loop	.Lmain			// decl ecx, jump if != 0
	popl	%edx
	decl	%edi
	decl	%eax
.Lstore:
	stosb
	jmp	.Lcopyloop

/*
 *  format %s
 */
stringfmt:
.Lstrcpy:
	movb	(%ebx),%al
	or	%al,%al
	jz	.Lcopyloop
	incl	%ebx
	stosb
	jmp	.Lstrcpy
