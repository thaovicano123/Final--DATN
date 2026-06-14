OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
  ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
  RAM (rwx) : ORIGIN = 0x10000000, LENGTH = 64K
}

SECTIONS
{
  . = ORIGIN(ROM);

  .init 0x00000000 : {
    KEEP(*(.init))
  } > ROM

  .irq 0x00000010 : {
    KEEP(*(.irq))
  } > ROM

  .text : ALIGN(16) {
    *(.text*)
    *(.rodata*)
  } > ROM

  _sidata = LOADADDR(.data);
  .data : {
    _sdata = .;
    *(.data*)
    _edata = .;
  } > RAM AT > ROM

  .bss (NOLOAD) : {
    _sbss = .;
    *(.bss*)
    *(COMMON)
    _ebss = .;
  } > RAM

  . = ALIGN(16);
  _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
