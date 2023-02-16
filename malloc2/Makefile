flags = -g -Wall -no-pie
PROG = malloc

all: $(PROG)

$(PROG): avalia.o meuAlocador.o
	gcc $(flags) -o $(PROG) avalia.o meuAlocador.o

avalia.o: avalia.c
	gcc $(flags) -c avalia.c -o avalia.o

meuAlocador.o: meuAlocador.h meuAlocador.s
	as $(flags) meuAlocador.s -o meuAlocador.o

clean:
	rm -rf *.o $(PROG)