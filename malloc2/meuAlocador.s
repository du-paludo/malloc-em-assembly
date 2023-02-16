# as malloc.s -o malloc.o -g; ld malloc.o -o malloc -g

# registradores usados - rbx > rcx > rdx > rsi > r10-r15
# rax - retorno e parâmetro do syscall
# rdi - novo valor da brk


.section .data
    INICIO_HEAP: .quad 0
    TOPO_HEAP: .quad 0
    TOPO_ALOCADO: .quad 0
    
    strGerencial: .string "################"
    charLivre: .string "-"
    charOcupado: .string "+"
    charLinha: .string "\n\n"


.section .text
# .globl _start

.globl iniciaAlocador
.type iniciaAlocador, @function
iniciaAlocador:
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


.globl finalizaAlocador
.type finalizaAlocador, @function
finalizaAlocador:
    pushq %rbp
    movq %rsp, %rbp

    movq $12, %rax              # código da syscall para o brk
    movq INICIO_HEAP, %rdi      # brk restaura valor inicial da heap
    syscall

    popq %rbp
    ret


.globl alocaMem
.type alocaMem, @function
alocaMem:
    pushq %rbp
    movq %rsp, %rbp
    subq $24, %rsp

    movq %rdi, -24(%rbp)

    movq $0, -8(%rbp)           # inicializa o endereço do menor bloco com 0

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
            cmpq -24(%rbp), %rsi         # %rsi (tamanho) < num_bytes ==> fim_if
            jl fim_if
                cmpq $0, -8(%rbp)
                je if_menor
                cmpq -16(%rbp), %rsi
                jge fim_if
                    if_menor:
                    movq %rcx, -8(%rbp)
                    movq %rsi, -16(%rbp)
      
        fim_if:
        # rcx passa a apontar para o início do próximo bloco
        addq $16, %rcx          # %rcx (i) <-- %rcx (i) + 16
        addq %rsi, %rcx         # %rcx (i) <-- %rcx (i) + %rsi (tamanho)
        jmp while

    fim_while:
    cmpq $0, -8(%rbp)
    je aloca_topo
        movq -8(%rbp), %rcx
        movq $1, (%rcx)         # informa que o bloco está ocupado

        movq 8(%rcx), %r10      # r10 < tam antigo do bloco

        movq -24(%rbp), %r11    # r11 < tam novo do bloco
        movq %r11, %rdx         # rdx < r11

        addq $16, %rcx
        
        movq %rcx, %r12         # r12 < inicio do conteudo do bloco
        addq %r10, %r12         # r12 < inicio do próximo bloco alocado
        
        addq %rcx, %r11         # r11 < inicio do bloco livre
        movq %r11, %rsi

        subq %r11, %r12         # r12 < r12 - r11 (tam livre)
        cmpq $16, %r12
        jle nao_espaco_livre
            movq %rdx, -8(%rcx)      # tam do bloco < r11
            movq $0, (%rsi)
            subq $16, %r12
            movq %r12, 8(%rsi)


        nao_espaco_livre:
        

        addq 8(%rcx), %r12

        movq %rcx, %rax         # retorna o endereço do bloco (início do conteúdo)
        addq $24, %rsp
        popq %rbp
        ret

    aloca_topo:
    # obtém o endereço do topo do último bloco alocado e o endereço do topo dos bytes alocados na heap
    movq TOPO_HEAP, %rdx        # %rdx <-- TOPO_HEAP (último bloco alocado)
    movq TOPO_ALOCADO, %rcx     # %rcx <-- TOPO_ALOCADO (topo dos bytes alocados na heap)

    movq -24(%rbp), %rbx         # %rbx <-- num_bytes (parâmetro)
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
    movq -24(%rbp), %rcx     # %rcx <-- num_bytes (parâmetro)
    movq %rcx, 8(%rbx)      # M[%rbx + 8] <-- num_bytes (parâmetro)
    
    addq $16, TOPO_HEAP     # TOPO_HEAP += 16
    addq %rcx, TOPO_HEAP    # TOPO_HEAP += num_bytes (parâmetro)
    
    addq $16, %rbx          # %rbx <-- %rbx + 8
    movq %rbx, %rax         # %rax <-- %rbx (endereço do bloco)

    addq $24, %rsp
    popq %rbp
    ret


.globl liberaMem
.type liberaMem, @function
liberaMem:
    pushq %rbp
    movq %rsp, %rbp
    subq $8, %rsp

    movq %rdi, -8(%rbp)

    # coloca 0 no bit de ocupado
    movq -8(%rbp), %r10     # %rbx <-- %rdi (parâmetro)
    movq $0, -16(%r10)      # M[%rbx - 16] <-- 0
    
    call concatena
    call concatena

    addq $8, %rsp
    popq %rbp
    ret

concatena:
    pushq %rbp
    movq %rsp, %rbp

    movq TOPO_HEAP, %rax
    movq INICIO_HEAP, %rbx

    # itera cada bloco da heap até chegar no topo
    while2:
    cmpq %rax, %rbx             # %rbx (i) >= %rax (topo) ==> fim_while
    jge fim_while2
        cmpq $0, (%rbx)
        jne fim_if4
            movq 8(%rbx), %rcx
            movq %rbx, %rsi
            addq $16, %rsi
            addq %rcx, %rsi
            cmpq $0, (%rsi)
            jne fim_if4
                movq 8(%rsi), %rdx
                addq $16, %rdx
                addq %rdx, 8(%rbx)
        fim_if4:
        movq 8(%rbx), %rsi
        addq $16, %rbx          # %rbx (i) <-- %rbx (i) + 16
        addq %rsi, %rbx         # %rbx (i) <-- %rbx (i) + %rsi (tamanho)
        jmp while2
    fim_while2:

    popq %rbp
    ret


.globl imprimeMapa
.type imprimeMapa, @function
imprimeMapa:
    pushq %rbp
    movq %rsp, %rbp

    subq $8, %rsp               # aloca espaço para variável local
    movq TOPO_HEAP, %r10        # %r10 <-- TOPO_HEAP
    movq %r10, -8(%rbp)         # iterador_bloco <-- TOPO_HEAP

    movq INICIO_HEAP, %r12
    while_bloco:
    cmpq -8(%rbp), %r12                 # -8(%rbp) (iterador_bloco) >= %rcx (TOPO_HEAP) ==> fim_while_bloco
    jge fim_while_bloco
        movq $strGerencial, %rsi    # segundo argumento do write: ponteiro para a mensagem a ser escrita
        movq $16, %rdx              # terceiro argumento do write: tamanho da mensagem
        movq $1, %rax               # número do sistema para write (1)
        movq $1, %rdi               # primeiro argumento do write: descritor de arquivo (1 é stdout)
        syscall                     # chama o sistema write
        
        movq (%r12), %r13           # %r13 (bit_ocupado) <-- M[%rcx]
        movq 8(%r12), %r14          # %r14 (tamanho) <-- M[%rcx + 8]
        movq $0, %r15               # %r15 (iterador) <-- 0
        while_imprime:
        cmpq %r14, %r15             # r15 (i) >= r14 (tamanho) ==> fim_while_imprime 
        jge fim_while_imprime
            movq $1, %rdi           # argumentos para o write
            movq $1, %rdx
            movq $1, %rax
            cmpq $0, %r13           # r13 (bit_ocupado) == 0 ==> imprime_else
            jne imprime_else        
                movq $charLivre, %rsi       # imprime charLivre "-"
                jmp fim_imprime_if          # fim imprime_if             
            imprime_else:
                movq $charOcupado, %rsi     # imprime charOcupado "+"
            fim_imprime_if:
            syscall
            addq $1, %r15                   # r15 (i)++
            jmp while_imprime               # volta para o while_imprime
            
        fim_while_imprime:
        addq $16, %r12                      # r12 (iterador_bloco) += 16 (informações gerenciais)
        addq %r14, %r12                     # r12 (iterador_bloco) += r14 (tamanho)
        jmp while_bloco
        
    fim_while_bloco:
    movq $charLinha, %rsi
    movq $2, %rdx
    movq $1, %rax
    movq $1, %rdi
    syscall

    addq $8, %rsp
    popq %rbp
    ret


; _start:
;     pushq %rbp
;     movq %rsp, %rbp

;     subq $16, %rsp              # x = -8(%rbp), y = -16(%rbp)

;     call iniciaAlocador     # chama a função iniciaAlocador

;     movq $20, %rbx              # coloca num_bytes em %rbx
;     pushq %rbx                  # empilha num_bytes (parâmetro)
;     call alocaMem               # chama a função alocaMem
;     addq $8, %rsp               # desempilha o parâmetro
;     movq %rax, -8(%rbp)         # x <-- %rax

;     movq $300, %rbx
;     pushq %rbx
;     call alocaMem
;     addq $8, %rsp
;     movq %rax, -16(%rbp)        # y <-- %rax

;     movq -8(%rbp), %rbx         # coloca x (ponteiro para algum bloco da heap) em %rbx
;     pushq %rbx                  # empilha x (parâmetro)
;     call liberaMem              # chama a função liberaMem
;     addq $8, %rsp               # desempilha o parâmetro

;     movq $400, %rbx
;     pushq %rbx
;     call alocaMem
;     addq $8, %rsp
;     movq %rax, -8(%rbp)

;     movq $12, %rax              # código da syscall para o brk
;     movq $0, %rdi               # retorna endereço atual da heap em %rax
;     syscall

;     call imprimeMapa

;     call finalizaAlocador       # chama a função finalizaAlocador
;     addq $16, %rsp              # remove o espaço alocado para duas variáveis locais

;     movq $0, %rdi
;     movq $60, %rax              # encerra o programa
;     syscall

