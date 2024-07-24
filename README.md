# Malloc in Assembly

This repository provides a custom memory allocator implemented in C with assembly routines. This memory allocator includes basic functions for memory management: allocation, deallocation, and heap initialization.

## Functions

### iniciaAlocador
Initializes the memory allocator by setting up the initial heap state.

### finalizaAlocador
Finalizes the memory allocator by resetting the heap to its initial state.

### alocaMem
Allocates a memory block of the requested size.

### liberaMem
Frees a previously allocated memory block.

### imprimeMapa
Prints the current state of the heap, showing which blocks are occupied and which are free.

## Heap Visualization

The imprimeMapa function prints a visual representation of the heap:

- \+ indicates an occupied block.
- \- indicates a free block.
- ################ indicates the management block.
  
**Example output:**

```shell
################
++++++++++++----
################
++++++++++++----++++++++++++++
################
++++++++++++----++++++++++++++++++++++++++++
```

## Compilation

To compile the project, use the following commands:

```sh
as malloc.s -o malloc.o -g
ld malloc.o -o malloc -g
```

## Registers Used
- **rbx** > **rcx** > **rdx** > **rsi** > **r10-r15**
- **rax**: Return and parameter for syscall
- **rdi**: New value for brk

The assembly code is divided into different sections for data and text, handling the various operations of the memory allocator.
