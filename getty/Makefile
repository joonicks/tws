
all:		getty

getty:		getty.c asmgetty.S data.S
		$(CC) $(CFLAGS) -o $@ asmgetty.S getty.c data.S -nostdlib
		size $@
		@echo ''
		@echo 'Remember, use "make strip" to make the 4K variant.'
		@echo ''

strip:		getty
		strip getty
		objcopy -R .bss -R .data -R .note -R .comment getty

#		objcopy --set-section-flags=.text=contents,alloc,load,code getty

