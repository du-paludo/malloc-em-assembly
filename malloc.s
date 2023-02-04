# as malloc.s -o malloc.o
# ld malloc.o -o malloc

# prioridades - rbx > rcx > rdx > rsi
# temporarios - r10-r15

# rax = retorno e parâmetro do brk
# rdi = novo valor da brk


.section .data
    INICIO_HEAP: .quad 0
    TOPO_HEAP: .quad 0
    TOPO_ALOCADO: .quad 0

.section .text
.globl _start

inicializaAlocador:
    # monta o registro de ativação
    pushq %rbp
    movq %rsp, %rbp

    # inicializa o alocador
    movq $12, %rax              # código da syscall para o brk
    movq $0, %rdi               # retorna endereço atual da heap em %rax
    syscall                     # chamada de sistema para o brk
    
    movq %rax, INICIO_HEAP      # coloca endereço atual no INICIO_HEAP
    movq %rax, TOPO_HEAP        # coloca endereço atual no TOPO_HEAP
    movq %rax, TOPO_ALOCADO
    
    # finaliza e restaura o registro de ativação
    popq %rbp
    ret

finalizaAlocador:
    # monta o registro de ativação
    pushq %rbp
    movq %rsp, %rbp

    # finaliza o alocador
    movq $12, %rax              # código da syscall para o brk
    movq INICIO_HEAP, %rdi      # brk restaura valor inicial da heap
    syscall

    # finaliza e restaura o registro de ativação
    popq %rbp
    ret

alocaMem:
    # monta o registro de ativação
    pushq %rbp
    movq %rsp, %rbp

    # obtém o endereço do topo da heap e o endereco inicial da heap
    movq TOPO_HEAP, %rbx        # %rbx <-- TOPO_HEAP
    movq INICIO_HEAP, %rcx      # %rcx (i) <-- INICIO_HEAP

    # verifica se a heap está vazia
    while:
    cmpq %rbx, %rcx             # %rcx (i) >= %rbx (topo) ==> fim_while
    jge fim_while
        movq (%rcx), %rdx       # %rdx (bit_ocupado) <-- M[%rcx]

        # rcx passa a apontar para o tamanho do bloco
        addq $8, %rcx           # %rcx (i) <-- %rcx (i) + 8
        movq (%rcx), %rsi       # %rsi (tamanho) <-- M[%rcx]

        # verifica se o bloco está livre
        cmpq $0, %rdx           # %rdx (bit_ocupado) != 0 ==> fim_if
        jne fim_if

            # verifica se o bloco é suficiente
            cmpq 16(%rbp), %rsi         # %rsi (tamanho) < num_bytes ==> fim_if
            jl fim_if
                # informa que o bloco está ocupado
                movq $1, (%rdx)         # M[%rdx] <-- 1 (bit_ocupado) 

                # rcx passa a apontar para o conteúdo desse bloco bloco
                addq $8, %rcx           # %rcx (i) <-- %rcx (i) + 8

                # retorna o endereço do bloco (inicio do conteúdo)
                movq (%rcx), %rax       # %rax <-- M[%rcx]
                ret
                
        fim_if:
        # rcx passa a apontar para o conteúdo desse bloco bloco
        addq $8, %rcx           # %rcx (i) <-- %rcx (i) + 8

        # rcx passa a apontar para o início próximo bloco
        addq %rsi, %rcx         # %rcx (i) <-- %rcx (i) + %rsi (tamanho)
        jmp while

    fim_while:
        # obtém o endereço do topo do último bloco alocado e o endereço do topo dos bytes alocados na heap
        movq TOPO_HEAP, %rdx        # %rdx <-- TOPO_HEAP (último bloco alocado)
        movq TOPO_ALOCADO, %rcx     # %rcx <-- TOPO_ALOCADO (topo dos bytes alocados na heap)

        movq 16(%rbp), %rbx         # %rbx <-- num_bytes (parâmetro)
        addq $16, %rbx              # %rbx <-- num_bytes + 16

        # verifica se há espaço suficiente para o bloco dentro dos bytes já alocados
        subq %rdx, %rcx             # %rdx <-- TOPO_ALOCADO - TOPO_HEAP
        cmpq %rcx, %rbx             # %rbx (tam_requerido + 16) <= (TOPO_ALOCADO - TOPO_HEAP) ==> fim_if2
        jle fim_if2
            subq %rcx, %rbx         # %rbx <-- num_bytes + 16 - (TOPO_ALOCADO - TOPO_HEAP)

            # calcula o número de K blocos de 4096 bytes necessários
            
            # K = ((tam_requerido - 1) / 4096) + 1
            subq $1, %rbx           # rbx -= 1  |   K = tam_requerido - 1
            shr $12, %rbx           # rbx /= 4096   |   K = K / 4096
            addq $1, %rbx           # rbx += 1  |   K = K + 1
            
            # calcula o número de bytes necessários

            # num_bytes = K * 4096
            shl $12, %rbx           # rbx *= 4096   |   num_bytes = K * 4096

            # adiciona o número de bytes necessários ao topo alocado
            addq %rbx, TOPO_ALOCADO # TOPO_ALOCADO += rbx

            # chama o brk para aumentar o tamanho da heap
            movq TOPO_ALOCADO, %rdi         # rdi <-- topo_alocado
            movq $12, %rax          # chamada de sistema para o brk
            syscall

        fim_if2:
            # informa que o bloco está ocupado
            movq TOPO_HEAP, %rbx    # %rbx <-- TOPO_HEAP

            movq $0, %rdi
            movq $12, %rax
            syscall

            movq $1, (%rbx)         # M[%rbx] <-- 1 (bit_ocupado)
            
            # %rbx passa a apontar para o tamanho do bloco
            addq $8, %rbx           # %rbx <-- %rbx + 8
            movq 16(%rbp), %r10     # %r10 <-- num_bytes (parâmetro)
            movq %r10, (%rbx)       # M[%rbx] <-- num_bytes (parâmetro)
            
            movq (%rbx), %rcx       # %rcx <-- tamanho do bloco
            addq $16, TOPO_HEAP     # TOPO_HEAP += 16
            addq %rcx, TOPO_HEAP    # TOPO_HEAP += tamanho do bloco
            
            addq $8, %rbx           # %rbx <-- %rbx + 8
            movq %rbx, %rax         # %rax <-- %rbx (endereço do bloco)
            popq %rbp
            ret


liberaMem:
    # monta o registro de ativação
    pushq %rbp
    movq %rsp, %rbp

    # libera memória
    movq 16(%rbp), %rbx     # rbx <-- %rdi (parâmetro)
    subq $16, %rbx          # rbx <-- %rdi - 16
    movq $0, (%rbx)         # M[%rbx] <-- 0
    movq $0, %rax           # %rax <-- 0 (retorno)

    # finaliza e restaura o registro de ativação
    popq %rbp
    ret

_start:
    pushq %rbp
    movq %rsp, %rbp

    subq $16, %rsp              # x = -8(%rsp), y = -16(%rsp)

    call inicializaAlocador

    movq $5000, %rbx            # coloca o valor 100 (número de bytes) em %rbx
    pushq %rbx                  # empilha o valor (parâmetro)
    call alocaMem               # chama a função alocaMem
    addq $8, %rsp               # desempilha o parâmetro
    movq %rax, -8(%rbp)         # x <-- rax

    movq $300, %rbx             # coloca o valor 100 (número de bytes) em %rbx
    pushq %rbx                  # empilha o valor (parâmetro)
    call alocaMem               # chama a função alocaMem
    addq $8, %rsp               # desempilha o parâmetro
    movq %rax, -16(%rbp)        # x <-- rax

    movq -8(%rbp), %rbx
    pushq %rbx
    call liberaMem
    addq $8, %rsp

    movq $400, %rbx             # coloca o valor 100 (número de bytes) em %rax
    pushq %rbx                  # empilha o valor (parâmetro)
    call alocaMem               # chama a função alocaMem
    addq $8, %rsp               # desempilha o parâmetro
    movq %rax, -8(%rbp)         # x <-- rax



    call finalizaAlocador
    addq $16, %rsp

    movq TOPO_HEAP, %rdi
    movq $60, %rax
    syscall
