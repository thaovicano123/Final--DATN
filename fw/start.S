.section .init
.global _start

_start:
    la sp, _stack_top

    # Copy .data from ROM load address to RAM runtime address.
    la t0, _sidata
    la t1, _sdata
    la t2, _edata
1:
    beq t1, t2, 2f
    lw t3, 0(t0)
    sw t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    j 1b

    # Clear .bss section.
2:
    la t0, _sbss
    la t1, _ebss
3:
    beq t0, t1, 4f
    sw x0, 0(t0)
    addi t0, t0, 4
    j 3b

4:
    call main

halt:
    j halt
