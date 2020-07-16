/*
 *  data storage...
 */
.text

.global str_issue
.global str_login
.global str_term
.global str_dash
.global str_lf
.global str_dev
.global str_erase
.global str_ttyname
.global logname
.global str_prompt_login
.global prompt_sz
.global prompt

str_login:
	.asciz	"/bin/login"

str_term:
	.asciz	"TERM=linux"

str_dash:
	.asciz	"--"

str_lf:
	.asciz	"\n"

str_dev:
	.asciz	"/dev"

str_issue:
	.asciz	"/etc/issue"

str_erase:
	.asciz	"\010\040\010"
	.asciz	"\010\040\010"
	.asciz	"\210\240\210"
	.asciz	"\210\240\210"

str_prompt_login:
	.asciz	" login: "

prompt_sz:
	.long	0

prompt:
	.fill	80,1,0

str_ttyname:
	.fill	32,1,0

logname:
	.fill	128,1,0
