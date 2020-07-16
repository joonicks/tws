
VER =		5
PACKDIR =	twsinit-$(VER)
PACKAGE =	twsinit-$(VER).tar.gz

CFLAGS =	-g -Wshadow -Wall -m386 -O2 -fomit-frame-pointer
#CFLAGS =	-g -Wshadow -Wall -m386 -mcpu=i386 -march=i386 -O2 -fomit-frame-pointer
LFLAGS =	-g -nostdlib
CC =		gcc

EXTRA =

DOC =		BUGS INSTALL README README.KILLALL5

SRC =		init.c init.S killall5.c killall5.S printf.S runit.S
OBJ =		init_c.o init_S.o killall5_c.o killall5_S.o printf.o runit.o

INIT =		init
KILLALL5 =	killall5

all:		$(INIT) $(KILLALL5)

clean:		; rm -f $(INIT) $(KILLALL5) $(OBJ)

$(INIT):	init_S.o init_c.o printf.o runit.o
		$(CC) $(LFLAGS) -o $@ -c $^
		size init

$(KILLALL5):	killall5_c.o killall5_S.o printf.o
		$(CC) $(LFLAGS) -o $@ -c $^

c:		c.o killall5_S.o printf.o
		$(CC) $(LFLAGS) -o $@ -c $^

strip:		$(INIT) $(KILLALL5)
		strip $(INIT)
		strip $(KILLALL5)
		objcopy -R .note -R .comment -R .data -R .bss $(INIT)
		objcopy -R .note -R .comment -R .data -R .bss $(KILLALL5)

dist:
		mkdir $(PACKDIR)
		cp Makefile $(SRC) $(DOC) $(PACKDIR)
		tar cf - $(PACKDIR) | gzip -9 > $(PACKAGE)
		rm -rf $(PACKDIR)

init_c.o:	init.c
		$(CC) $(CFLAGS) -c $< -o $@ $(EXTRA)

init_S.o:	init.S
		$(CC) -c $< -o $@ $(EXTRA)

killall5_c.o:	killall5.c
		$(CC) $(CFLAGS) -c $< -o $@ $(EXTRA)

killall5_S.o:	killall5.S
		$(CC) -c $< -o $@ $(EXTRA)

printf.o:	printf.S
		$(CC) -c $< -o $@ $(EXTRA)

runit.o:	runit.S
		$(CC) -c $< -o $@ $(EXTRA)

