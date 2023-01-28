# as malloc.s -o malloc.o
# ld malloc.o -o malloc

.section .data
    INICIO_HEAP: .quad 0
    TOPO_HEAP: .quad 0

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

    movq TOPO_HEAP, %rax        # %rax <-- TOPO_HEAP
    movq INICIO_HEAP, %rbx      # %rbx <-- INICIO_HEAP
    cmpq %rax, %rbx             # %rbx != %rax ==> fim_if 
    jne fim_if
        movq TOPO_HEAP, %rdi    # %rdi <-- TOPO_HEAP
        addq 16(%rbp), %rdi     # %rdi <-- TOPO_HEAP + num_bytes
        addq $16, %rdi          # %rdi <-- TOPO_HEAP + num_bytes + 16
        movq $12, %rax          # chamada de sistema para o brk
        syscall
        movq TOPO_HEAP, %rax    # rax <-- TOPO_HEAP
        movq $1, (%rax)         # M[%rax] <-- 1
        addq $8, %rax           # rax <-- TOPO_HEAP + 8
        movq 16(%rbp), %rbx     # rbx <-- num_bytes
        movq %rbx, (%rax)       # M[%rax] <-- num_bytes
        addq $8, %rax           # rax <-- TOPO_HEAP + 16
        addq %rax, %rbx         # rbx <-- TOPO_HEAP + num_bytes + 16
        movq %rbx, TOPO_HEAP    # TOPO_HEAP <-- rbx
        popq %rbp
        ret                     # retorna %rax (endereço inicial do espaço alocado)

    fim_if:

        # Ver valor no campo de ocupado em cada bloco da heap
        # Se for igual a 0 (não ocupado), verifica se o tamanho é menor ou igual ao requerido
            # Se for menor ou igual, troca o bit para 1 (ocupado) e retorna o endereço
        # Se for igual a 1 (ocupado), lê o próximo campo (tamanho) e soma na variável de endereço
        # Retorna para o início do loop

        movq INICIO_HEAP, %rax  # %rax <-- INICIO_HEAP
        movq (%rax), rbx        # rbx <-- M[INICIO_HEAP]
        cmpq $0, %rbx           # rbx == 0 ==> fim_if2
        jne fim_if2

        fim_if2:
            

        popq %rbp
        ret

    # 

liberaMem:
    # monta o registro de ativação
    pushq %rbp
    movq %rsp, %rbp

    # libera memória
    movq 16(%rbp), %rbx         # rbx <-- %rdi (parâmetro)
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

    movq $100, %rax             # coloca o valor 100 (número de bytes) em %rax
    pushq %rax                  # empilha o valor (parâmetro)
    call alocaMem               # chama a função alocaMem
    addq $8, %rsp               # desempilha o parâmetro
    movq %rax, -8(%rsp)         # x <-- rax

    movq -8(%rsp), %rax
    pushq %rax
    call liberaMem
    addq $8, %rsp

    call finalizaAlocador
    addq $16, %rsp

    movq TOPO_HEAP, %rdi
    movq $60, %rax
    syscall
