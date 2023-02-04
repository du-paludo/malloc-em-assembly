i = INICIO_HEAP
while (i < TOPO_HEAP) {             // percorre a memória
    bit_ocupado = mem[i]            // 1 se ocupado, 0 se livre
    y = mem[i+8]                    // tamanho do bloco
    if bit_ocupado == 0 then        // se o bloco estiver livre
        if y >= tam_requerido then  // se o bloco for grande o suficiente
            bit_ocupado = 1         // marca como ocupado
            return i+16             // retorna o endereço do bloco
    i += 16 + y                     // pula para o próximo bloco
}
if tam_requerido + 16 > TOPO_ALOCADO - TOPO_HEAP    // se o bloco for pequeno o suficiente
    k = (tam_requerido + 16 - (TOPO_ALOCADO - TOPO_HEAP)) div 4097
    k = (tam_requerido-1) >> 12          // calcula quantos blocos de 4KB são necessários
    k++                                 // incrementa em 1 para garantir que o bloco seja grande o suficiente
    sbrk(k * 4096)                      // aloca mais k blocos de 4KB
else
    mem[TOPO_HEAP] = 1                              // marca como ocupado
    mem[TOPO_HEAP+8] = tam_requerido                // salva o tamanho do bloco
    TOPO_HEAP += 16 + tam_requerido                 // atualiza o topo da memória
    return TOPO_HEAP - tam_requerido                // retorna o endereço do bloco


k = (tam_requerido - 1) >> 12         // calcula quantos blocos de 4KB são necessários
k++                                 // incrementa em 1 para garantir que o bloco seja grande o suficiente
sbrk(k * 4096)                      // aloca mais k blocos de 4KB

mem[i] = 1                          // marca como ocupado
mem[i+8] = tam_requerido            // salva o tamanho do bloco
return i+16                         // retorna o endereço do bloco


// [1] -> [*2*] -> [3] -> [4] -> [1] |


// << SHIFT LEFT
// >> SHIFT RIGHT
// X = 0111 (7)
// X << 1 bit -> 1110 (7 * 2 = 14)
// X >> 1 bit -> 0011 (7 / 2 = 3)

// Y = 10001100101000 (9000)
// Y >> 12 bits -> 10 (2)


// TAPO_ALOCADO - INICIO_HEAP