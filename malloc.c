#include <stdio.h>
#include <unistd.h>

typedef struct nodo
{
	int ocupado;
	int tam;
	void* bloco;
	struct nodo* prox;
} nodo;


void* topoInicialHeap;
nodo* inicio_heap;
nodo* topo_heap;

void iniciaAlocador()
{
	inicio_heap = sbrk(0);
}

void finalizaAlocador()
{
	brk(topoInicialHeap);
}

int liberaMem(void* bloco)
{

}

void* alocaMem(int num_bytes)
{

}

int main()
{
	return 0;
}