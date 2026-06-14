// ============================================================================
// Startup + IRQ Vector cho LibreLane SoC (PicoRV32 Low-Power)
// Đặc điểm:
//   1. Full context save: ra, t0-t6, a0-a7 (16 registers = 64 bytes)
//      → IRQ handler có thể gọi C function an toàn.
//   2. maskirq unmask all IRQs tại boot.
//   3. .data copy ROM→RAM, .bss zeroing, stack setup.
// ============================================================================

.section .init
.global _start

_start:
    j _boot

.section .text
.global _boot

_boot:
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

    // PicoRV32 custom: maskirq x0, x0 (unmask all IRQs)
    .word 0x0600600b

    call main

halt:
    j halt

// ============================================================================
// IRQ VECTOR — Đặt tại 0x0000_0010 (PROGADDR_IRQ)
// Full context save để hỗ trợ C-callable IRQ handler.
// ============================================================================
.section .irq, "ax", @progbits
.global irq_vec

irq_vec:
    // ---- Full context save (16 regs = 64 bytes) ----
    addi sp, sp, -64
    sw ra,   0(sp)
    sw t0,   4(sp)
    sw t1,   8(sp)
    sw t2,  12(sp)
    sw t3,  16(sp)
    sw t4,  20(sp)
    sw t5,  24(sp)
    sw t6,  28(sp)
    sw a0,  32(sp)
    sw a1,  36(sp)
    sw a2,  40(sp)
    sw a3,  44(sp)
    sw a4,  48(sp)
    sw a5,  52(sp)
    sw a6,  56(sp)
    sw a7,  60(sp)

    // ---- IRQ Service Routine ----
    // Toggle GPIO bit[8] to mark every IRQ service visually.
    li t0, 0x2000200c
    li t1, 0x00000100
    sw t1, 0(t0)

    // Increment irq_count in RAM (observable by testbench/debugger).
    la t0, irq_count
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)

    // Auto-clear UART IRQ: reading RX register clears rx_valid_flag.
    li t0, 0x20000008
    lw t1, 0(t0)

    // ---- Full context restore ----
    lw ra,   0(sp)
    lw t0,   4(sp)
    lw t1,   8(sp)
    lw t2,  12(sp)
    lw t3,  16(sp)
    lw t4,  20(sp)
    lw t5,  24(sp)
    lw t6,  28(sp)
    lw a0,  32(sp)
    lw a1,  36(sp)
    lw a2,  40(sp)
    lw a3,  44(sp)
    lw a4,  48(sp)
    lw a5,  52(sp)
    lw a6,  56(sp)
    lw a7,  60(sp)
    addi sp, sp, 64

    // PicoRV32 custom: retirq (return from interrupt)
    .word 0x0400000b
