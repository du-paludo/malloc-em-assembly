flags = -g

all: malloc-firstfit malloc-bestfit malloc-nextfit

malloc-firstfit: malloc-firstfit.s
	as malloc-firstfit.s -o malloc-firstfit.o $(flags)
	ld malloc-firstfit.o -o malloc-firstfit $(flags)

malloc-bestfit: malloc-bestfit.s
	as malloc-bestfit.s -o malloc-bestfit.o $(flags)
	ld malloc-bestfit.o -o malloc-bestfit $(flags)

malloc-nextfit: malloc-nextfit.s
	as malloc-nextfit.s -o malloc-nextfit.o $(flags)
	ld malloc-nextfit.o -o malloc-nextfit $(flags)

clean:
	rm -f *~ *.o

purge: clean
	rm -f malloc-firstfit malloc-bestfit malloc-nextfit