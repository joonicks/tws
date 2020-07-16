#include <asm/unistd.h>

.global _start
.global tws_close
.global tws_execve
.global tws_exit
.global tws_open
.global tws_dup
.global tws_time
.global tws_write
.global tws_readc
.global tws_read
.global tws_ioctl
.global tws_fcntl
.global tws_sleep1
.global set_perm_stdio

.text
_start:
	popl	%edx                    // argc
	cmpl	$2,%edx
	jne	failexit
	movl	4(%esp),%esi
	testl	%esi,%esi
	jz	failexit
	cmpb	$0,(%esi)
	je	failexit
	/*
	 *  this part is very naughty, we're making the code segment writeable...
	 */
	movb	$7,%dl			// %edx == 2 as per above
	movl	$4096,%ecx
	movl	$_start,%ebx
	andl	$0xfffff000,%ebx
	push	$__NR_mprotect
	popl	%eax
	int	$0x80
	/*
	 *  copy ttyname to data buffer
	 */
	cld
	movl	$str_ttyname,%edi
.L1:
	lodsb
	stosb
	testb	%al,%al
	jnz	.L1
	/*
	 *  make the login prompt
	 */
	movl	$prompt,%edx
	movl	%edx,%edi
	movl	$'\r',(%edi)
	incl	%edi
	movl	$'\n',(%edi)
	incl	%edi
	movl	$_etext,%ebx
	push	$__NR_uname
	popl	%eax
	int	$0x80			// uname()
	leal	65(%ebx),%esi
.L2:
	lodsb
	stosb
	testb	%al,%al
	jnz	.L2
	decl	%edi
	movl	$str_prompt_login,%esi
.L3:
	lodsb
	stosb
	testb	%al,%al
	jnz	.L3
	decl	%edi
	subl	%edx,%edi
	movl	%edi,prompt_sz
	/*
	 *  unmap the "real" stack and use our own
	 *  (this is very very very very very nasty)
	 */
	movl	%esp,%ebx
	andl	$0xfffff000,%ebx
	movl	$4096,%ecx
	movl	$_etext+512,%esp
	push	$__NR_munmap
	popl	%eax
	int	$0x80
	/*
	 *
	 */
	push	$__NR_getpid
	popl	%eax
	int	$0x80
	push	%eax			// mypid
	/*
	 *
	 */
	push	$__NR_setsid
	popl	%eax
	int	$0x80
	/*
	 *
	 */
	/*
	 *
	 */
	xorl	%ebx,%ebx
	push	$__NR_close
	popl	%eax
	pushl	%eax
	int	$0x80
	popl	%eax
	pushl	%eax
	incl	%ebx
	int	$0x80
	popl	%eax
	incl	%ebx
	int	$0x80
	/*
	 *  chdir("/dev")
	 */
	movl	$str_dev,%ebx
	push	$__NR_chdir
	popl	%eax
	int	$0x80
	testl	%eax,%eax
	jnz	failexit
	/*
	 *  jump into main
	 */
	call	tws_main
	/*
	 *  no return
	 */

tws_execve:
	popl	%eax			// pop return address
	popl	%ebx			// pop arg 1 (path)
	popl	%ecx			// pop arg 2 (argv[])
	popl	%edx			// pop arg 3 (envp[])
	push	$__NR_execve
	popl	%eax
	int	$0x80
failexit:
	pushl	%eax
	pushl	%eax
	/* fall through */

tws_exit:
	popl	%ebx			// discard return address
	popl	%ebx
.Lexit:
	push	$__NR_exit
	popl	%eax
	int	$0x80
	/* no return */

tws_read:
	push	$__NR_read
	jmp	common_syscall3

tws_open:
	push	$__NR_open
	jmp	common_syscall3

tws_write:
	push	$__NR_write
	jmp	common_syscall3

tws_ioctl:
	push	$__NR_ioctl
	jmp	common_syscall3

tws_fcntl:
	push	$__NR_fcntl
	/* fall through */

common_syscall3:
	movl	0x10(%esp),%edx
	movl	0x0c(%esp),%ecx
common_syscall1:
	xchgl	0x08(%esp),%ebx
	popl	%eax
	int	$0x80
	movl	0x04(%esp),%ebx
	ret

tws_close:
	push	$__NR_close
	jmp	common_syscall1

tws_dup:
	push	$__NR_dup
	jmp	common_syscall1

tws_time:
	push	$__NR_time
	jmp	common_syscall1

tws_readc:
	pushl	%ebx
	push	$1
	popl	%edx			// read 1 char
	movl	8(%esp),%ecx		// (char*)&c
	xorl	%ebx,%ebx		// fd == 0
	push	$__NR_read
	popl	%eax
	int	$0x80
	cmpl	$-126,%eax
	ja	.Lexit
	popl	%ebx
	ret

tws_sleep1:
	xorl	%ecx,%ecx
	push	%ebx
	push	%ecx
	push	$1
	movl	%esp,%ebx
	xorl	%eax,%eax
	movb	$__NR_nanosleep,%al
	int	$0x80
	popl	%ebx
	popl	%ebx
	popl	%ebx
	ret

set_perm_stdio:
	pushl	%ebx
	xorl	%edx,%edx		// group = 0
	xorl	%ecx,%ecx		// user = 0
	xorl	%ebx,%ebx		// stdio (fd = 0)
	push	$__NR_fchown		// fchown()
	popl	%eax
	int	$0x80
	movb	$0x80,%cl		// trick $0x180 into %ecx == mode 0600
	incb	%ch
	push	$__NR_fchmod		// fchmod()
	popl	%eax
	int	$0x80
	popl	%ebx
	ret

