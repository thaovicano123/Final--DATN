# PicoRV32 Interface Notes

## 1) Native Memory Interface

### Signals summary
- `mem_valid`: CPU starts a transfer and keeps it high until accepted.
- `mem_ready`: slave acknowledges transfer completion.
- `mem_instr`: high for instruction fetch transfers.
- `mem_addr`: byte address of access.
- `mem_wdata`: write data.
- `mem_wstrb`: byte enables. `0000` means read, non-zero means write.
- `mem_rdata`: read data sampled when `mem_ready` is high.

### Read transaction timing (your explanation)
- CPU drives `mem_addr`, asserts `mem_valid`, and sets `mem_wstrb = 0000`.
- Slave returns data on `mem_rdata` and asserts `mem_ready` in the completing cycle.
- CPU completes transfer when `mem_valid && mem_ready`.

### Write transaction timing (your explanation)
- CPU drives `mem_addr`, `mem_wdata`, and non-zero `mem_wstrb`, then asserts `mem_valid`.
- Slave writes selected bytes and asserts `mem_ready` to acknowledge.
- CPU completes transfer when `mem_valid && mem_ready`.

### Byte-enable usage (`mem_wstrb`) examples
- `1111`: write 32-bit word
- `0011`: write lower 16-bit halfword
- `1100`: write upper 16-bit halfword
- `0001`, `0010`, `0100`, `1000`: write one selected byte

## 2) AXI4-Lite Option

### Module options
- `picorv32`: native valid-ready memory interface (simple integration).
- `picorv32_axi`: AXI4-Lite master interface from CPU directly.
- `picorv32_axi_adapter`: bridge native interface to AXI4-Lite.

### Which option I choose for this project and why
- Choose native interface (`picorv32`) for this student SoC because it reduces bus complexity and speeds up bring-up.
- A simple address decoder is enough for ROM/RAM/UART/SPI/GPIO.
- If integrating with existing AXI subsystem later, add `picorv32_axi_adapter`.

## 3) Interrupts (IRQ)

### Core behavior
- `irq` input: 32-bit pending interrupt bitmap into core.
- `eoi` output: End-Of-Interrupt indicator for IRQ(s) being handled.
- Internal IRQ 0: SPI interrupt.
- Internal IRQ 1: EBREAK/ECALL or illegal instruction.
- Internal IRQ 2: bus error (unaligned memory access).

### Firmware handling idea
- Enable IRQ support with `ENABLE_IRQ=1`.
- Use assembly wrapper to save context and call C handler.
- C handler reads pending source mask, services SPI/UART/GPIO, then returns via IRQ return sequence.

## 4) Integration Decision

### Initial address map assumptions
- `0x0000_0000` - ROM (firmware image)
- `0x1000_0000` - RAM
- `0x2000_0000` - UART
- `0x2000_1000` - SPI
- `0x2000_2000` - GPIO
- `0x2000_3000` - CMU/clock-gating control registers

### Peripheral gating policy assumptions
- Keep CPU core clock ungated in phase 2 baseline.
- Gate peripheral clocks (UART/SPI/GPIO) using enable bits in CMU register map.
- Default enable after reset for debug visibility, then firmware disables unused blocks.
- Verify gated clocks remain static low in simulation when disabled.

## 5) Open questions
- Should ROM be modeled as combinational read or synchronous read in our RTL target?
- Do we need latched IRQ behavior (`LATCHED_IRQ`) for all external interrupt lines?
