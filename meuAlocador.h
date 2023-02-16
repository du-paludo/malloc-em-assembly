#ifndef __ALOCADOR_H__
#define __ALOCADOR_H__

void iniciaAlocador();

void *alocaMem(int tamanho);

void imprimeMapa();

void liberaMem(int *endereco);

void finalizaAlocador();

#endif