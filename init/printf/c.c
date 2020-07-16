
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(void)
{
	char	*f;

	f = "a:%s b:%s c:%i d:%i e:%i\n";
	Printf(f,"hello","world",123,-123,0);
	Printf("%s",f);

	f = "%i %i %i %i\n";
	Printf(f,1,2,3,4);
	Printf("%s",f);

	f = "%i\n";
	Printf(f,0);
	Printf("%s",f);

	exit(0);
}
