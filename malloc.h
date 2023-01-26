#ifndef _MALLOC_
#define _MALLOC_

void iniciaAlocador();

void finalizaAlocador();

int liberaMem(void* bloco);

void* alocaMem(int num_bytes);

#endif