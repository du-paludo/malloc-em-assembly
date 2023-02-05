# as malloc.s -o malloc.o -g; ld malloc.o -o malloc -g

# registradores usados - rbx > rcx > rdx > rsi > r10-r15
# rax - retorno e parâmetro do syscall
# rdi - novo valor da brk


.section .data
    INICIO_HEAP: .quad 0
    TOPO_HEAP: .quad 0
    TOPO_ALOCADO: .quad 0

.section .bss
    .equ TAM_BUFFER, 8
    .lcomm BUFFER, TAM_BUFFER

.section .text
.globl _start


inicializaAlocador:
    pushq %rbp                  # empilha rbp antigo
    movq %rsp, %rbp             # atualiza o novo valor de rbp

    movq $12, %rax              # código da syscall para o brk
    movq $0, %rdi               # retorna endereço atual da heap em %rax
    syscall                     # chamada de sistema para o brk
    
    movq %rax, INICIO_HEAP      # coloca endereço inicial da heap em INICIO_HEAP
    movq %rax, TOPO_HEAP        # coloca endereço inicial da heap em TOPO_HEAP
    movq %rax, TOPO_ALOCADO     # coloca endereço inicial da heap em TOPO_ALOCADO
    
    popq %rbp                   # desempilha e restaura o valor antigo de rbp
    ret                         # finaliza a função


finalizaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    movq $12, %rax              # código da syscall para o brk
    movq INICIO_HEAP, %rdi      # brk restaura valor inicial da heap
    syscall

    popq %rbp
    ret


alocaMem:
    pushq %rbp
    movq %rsp, %rbp

    movq TOPO_HEAP, %rbx        # %rbx (topo) <-- TOPO_HEAP
    movq INICIO_HEAP, %rcx      # %rcx (i) <-- INICIO_HEAP

    # itera cada bloco da heap até chegar no topo
    while:
    cmpq %rbx, %rcx             # %rcx (i) >= %rbx (topo) ==> fim_while
    jge fim_while
        movq (%rcx), %rdx       # %rdx (bit_ocupado) <-- M[%rcx]
        movq 8(%rcx), %rsi      # %rsi (tamanho) <-- M[%rcx + 8]

        # verifica se o bloco está livre
        cmpq $0, %rdx           # %rdx (bit_ocupado) != 0 ==> fim_if
        jne fim_if
            # verifica se o tamanho do bloco é suficiente
            cmpq 16(%rbp), %rsi         # %rsi (tamanho) < num_bytes ==> fim_if
            jl fim_if
                movq $1, (%rcx)         # informa que o bloco está ocupado
                addq $16, %rcx
                movq %rcx, %rax         # retorna o endereço do bloco (início do conteúdo)
                popq %rbp
                ret
      
        fim_if:
        # rcx passa a apontar para o início do próximo bloco
        addq $16, %rcx          # %rcx (i) <-- %rcx (i) + 16
        addq %rsi, %rcx         # %rcx (i) <-- %rcx (i) + %rsi (tamanho)
        jmp while

    fim_while:
    # obtém o endereço do topo do último bloco alocado e o endereço do topo dos bytes alocados na heap
    movq TOPO_HEAP, %rdx        # %rdx <-- TOPO_HEAP (último bloco alocado)
    movq TOPO_ALOCADO, %rcx     # %rcx <-- TOPO_ALOCADO (topo dos bytes alocados na heap)

    movq 16(%rbp), %rbx         # %rbx <-- num_bytes (parâmetro)
    addq $16, %rbx              # %rbx <-- num_bytes + 16

    # verifica se não há espaço suficiente para o bloco dentro dos bytes já alocados
    subq %rdx, %rcx             # %rdx <-- TOPO_ALOCADO - TOPO_HEAP
    cmpq %rcx, %rbx             # %rbx (num_bytes + 16) <= %rcx (TOPO_ALOCADO - TOPO_HEAP) ==> fim_if2
    jle fim_if2
        subq %rcx, %rbx             # %rbx <-- num_bytes + 16 - (TOPO_ALOCADO - TOPO_HEAP)

        # calcula o número de K (%rbx) blocos de 4096 bytes necessários
        subq $1, %rbx               # %rbx -= 1
        shr $12, %rbx               # %rbx /= 4096
        addq $1, %rbx               # %rbx += 1
        
        # calcula o número de bytes necessários e adiciona ao TOPO_ALOCADO
        shl $12, %rbx               # %rbx *= 4096
        addq %rbx, TOPO_ALOCADO     # TOPO_ALOCADO += rbx

        # chama brk para aumentar o tamanho da heap
        movq TOPO_ALOCADO, %rdi     # %rdi <-- TOPO_ALOCADO
        movq $12, %rax              # chamada de sistema para o brk
        syscall    

    fim_if2:
    movq TOPO_HEAP, %rbx    # %rbx <-- TOPO_HEAP

    movq $1, (%rbx)         # M[%rbx] <-- 1 (bit_ocupado)
    movq 16(%rbp), %rcx     # %rcx <-- num_bytes (parâmetro)
    movq %rcx, 8(%rbx)      # M[%rbx + 8] <-- num_bytes (parâmetro)
    
    addq $16, TOPO_HEAP     # TOPO_HEAP += 16
    addq %rcx, TOPO_HEAP    # TOPO_HEAP += num_bytes (parâmetro)
    
    addq $16, %rbx          # %rbx <-- %rbx + 8
    movq %rbx, %rax         # %rax <-- %rbx (endereço do bloco)

    popq %rbp
    ret


liberaMem:
    pushq %rbp
    movq %rsp, %rbp

    # coloca 0 no bit de ocupado
    movq 16(%rbp), %rbx     # %rbx <-- %rdi (parâmetro)
    movq $0, -16(%rbx)      # M[%rbx - 16] <-- 0
    movq $0, %rax           # %rax <-- 0 (retorno)

    popq %rbp
    ret


imprimeMapa:
    pushq %rbp
    movq %rsp, %rbp

    movq INICIO_HEAP, %r10
    movq (%r10), %rdi
    movq $BUFFER, %rsi
    movq $8, %rdx
    movq $0, %rax
    syscall
    
    movq $1, %rdi               # primeiro argumento: descritor de arquivo (1 é stdout)
    movq $BUFFER, %rsi          # segundo argumento: ponteiro para a mensagem a ser escrita
    movq $8, %rdx               # terceiro argumento: tamanho da mensagem
    movq $1, %rax               # número do sistema para write (1)
    syscall                     # chama o sistema write

    popq %rbp
    ret


_start:
    pushq %rbp
    movq %rsp, %rbp

    subq $16, %rsp              # x = -8(%rbp), y = -16(%rbp)

    call inicializaAlocador     # chama a função inicializaAlocador

    movq $5000, %rbx            # coloca num_bytes em %rbx
    pushq %rbx                  # empilha num_bytes (parâmetro)
    call alocaMem               # chama a função alocaMem
    addq $8, %rsp               # desempilha o parâmetro
    movq %rax, -8(%rbp)         # x <-- %rax

    movq $300, %rbx
    pushq %rbx
    call alocaMem
    addq $8, %rsp
    movq %rax, -16(%rbp)        # y <-- %rax

    movq -8(%rbp), %rbx         # coloca x (ponteiro para algum bloco da heap) em %rbx
    pushq %rbx                  # empilha x (parâmetro)
    call liberaMem              # chama a função liberaMem
    addq $8, %rsp               # desempilha o parâmetro

    movq $400, %rbx
    pushq %rbx
    call alocaMem
    addq $8, %rsp
    movq %rax, -8(%rbp)

    movq $12, %rax              # código da syscall para o brk
    movq $0, %rdi               # retorna endereço atual da heap em %rax
    syscall

    call imprimeMapa

    call finalizaAlocador       # chama a função finalizaAlocador
    addq $16, %rsp              # remove o espaço alocado para duas variáveis locais

    movq $0, %rdi
    movq $60, %rax              # encerra o programa
    syscall
