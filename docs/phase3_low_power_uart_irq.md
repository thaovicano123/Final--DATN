# Phase 3: Low-Power UART IRQ Architecture

## Overview
**Objective**: Eliminate SPI peripheral and replace its interrupt mechanism with UART interrupt for low-power operation.

### Key Achievement
- ✅ SPI module completely removed (RTL, testbenches, third-party models)
- ✅ UART IRQ unconditionally connected to CPU IRQ[0]
- ✅ CPU configured with interrupts enabled (ENABLE_IRQ=1)
- ✅ Trap handler installed at PROGADDR_IRQ (0x10)
- ✅ Clock gating reduced from 3 domains (UART, SPI, GPIO) to 2 (UART, GPIO)
- ✅ Smoke test passing with GPIO activity confirmed

---

## Hardware Changes

### 1. SPI Removal
**Deleted files:**
- `rtl/spi_mmio.v` - SPI peripheral controller
- `tb/tb_spi.v` - SPI testbench
- Third-party SPI models

**Module-level updates:**
- `rtl/soc_top.v`: Removed SPI instance; tied off SPI signals
- `rtl/soc_top_asic.v`: Same changes
- `rtl/cmu.v`: Removed `icg_cell u_icg_spi`; reduced `clk_en_state` from 3 to 2 bits
- `rtl/bus_decoder.v`: Set `assign sel_spi = 1'b0` (permanently disabled)

### 2. UART IRQ Integration
**UART Module (`rtl/real_uart_mmio.v`):**
```verilog
// Added unconditional IRQ output
output wire irq_rx

// Auto-clear on read (no gating register needed)
assign irq_rx = rx_valid_flag;
```

**Top-Level Wiring (`rtl/soc_top.v` & `rtl/soc_top_asic.v`):**
```verilog
// Route UART IRQ to CPU IRQ[0]
wire uart_irq;
assign irq = {31'd0, uart_irq};

// Connect UART interrupt output
real_uart_mmio u_uart (
    ...
    .irq_rx(uart_irq)
);

// Enable CPU interrupt handling
picorv32 #(
    .ENABLE_IRQ(1),
    .PROGADDR_IRQ(32'h0000_0010),
    .ENABLE_IRQ_QREGS(1)
) u_cpu (
    ...
    .irq(irq)
);
```

### 3. Clock Gating Optimization
**CMU (`rtl/cmu.v`) - Reduced clock gating domains:**

| Domain | Signal | Status | Notes |
|--------|--------|--------|-------|
| UART | `gclk_uart` | ✅ Active | Controlled by `clk_en[0]` |
| GPIO | `gclk_gpio` | ✅ Active | Controlled by `clk_en[1]` |
| SPI | `gclk_spi` | ❌ Removed | Power optimization |

**Before:** `clk_en` = 3-bit register (UART, SPI, GPIO)  
**After:** `clk_en` = 2-bit register (UART, GPIO)

---

## Firmware Changes

### 1. Configuration (`fw/main.c`)
**Clock Enable:**
```c
// Removed SPI bit (was 0x00000007)
// Now: UART (bit 0) + GPIO (bit 1) only
mmio_write(CMU_BASE + CMU_CLK_EN, 0x00000003u);
```

**UART ISR Handler:**
```c
void uart_irq_handler(void)
{
    uint32_t rx_status = mmio_read(UART_BASE + UART_RXDATA);
    
    // Bit[31] = valid flag, auto-clears on read
    if (rx_status & 0x80000000u) {
        uint8_t rx_byte = (uint8_t)(rx_status & 0xFFu);
        irq_count++;
        // Process received byte here
    }
}
```

### 2. Trap Handler (`fw/start.S`)
**Entry Point at 0x0:** Standard RISC-V initialization
- Load stack pointer to 0x10010000 (end of RAM)
- Copy `.data` from ROM to RAM
- Clear `.bss` section
- Call `main()`

**Interrupt Vector at 0x10 (PROGADDR_IRQ):**
- PicoRV32 automatically jumps here on interrupt
- Calls `uart_irq_handler()` via trap entry code
- Returns with `unimp` (PicoRV32-specific return-from-interrupt)

---

## Interrupt Flow

```
UART RX Byte Arrives
        ↓
uart_irq_handler() called by CPU (trap at 0x10)
        ↓
irq_rx signal asserts (unconditional)
        ↓
CPU latches IRQ and jumps to PROGADDR_IRQ
        ↓
Software reads UART_RXDATA (0x08)
        ↓
IRQ flag auto-clears (hardware behavior)
        ↓
ISR returns, CPU resumes main code or WFI
```

### Key Properties
- **No polling**: UART IRQ is unconditional (always asserts on valid RX byte)
- **Auto-clear**: Reading RX register clears the flag automatically
- **Low-latency**: CPU wakes immediately upon RX byte arrival
- **Scalable**: Multiple ISR handlers can be added at future PROGADDR_IRQ offsets

---

## Memory Layout

| Address Range | Purpose | Size |
|---------------|---------|------|
| 0x0000_0000 - 0x0000_FFFF | ROM (firmware code) | 64 KB |
| 0x0000_0010 | Trap vector (PROGADDR_IRQ) | - |
| 0x1000_0000 - 0x1000_FFFF | RAM (.data, .bss, stack) | 64 KB |
| 0x2000_0000 - 0x2000_0FFF | UART MMIO | - |
| 0x2000_2000 - 0x2000_2FFF | GPIO MMIO | - |
| 0x2000_3000 - 0x2000_3FFF | CMU MMIO | - |

---

## Testing Results

### Smoke Test
```
SOC_TOP_SMOKE: PASS (GPIO activity observed)
```
- Firmware boots successfully
- GPIO toggles correctly
- System runs without errors

### UART Testbench (Phase 2)
- TEST 1: TX transmission ✅
- TEST 2: RX byte triggers `irq_rx` ✅  
- TEST 3: CPU read of RX data auto-clears IRQ ✅

---

## Low-Power Operation (Design, Not Simulated)

### WFI (Wait For Interrupt) Instruction
In production deployment:
```c
// CPU sleeps until interrupt
asm volatile(".word 0x10500033");  // WFI opcode
```

### Power Savings
1. **Eliminate polling**: CPU sleeps instead of spinning on UART status
2. **Single interrupt source**: UART RX can wake CPU from sleep
3. **No SPI overhead**: Removed unused SPI power consumption
4. **Gated clocks**: Only UART and GPIO clocks active when needed

### Typical Flow
```
CPU enters WFI
    ↓ (CPU idles, clock disabled)
UART receives byte
    ↓ (uart_irq asserts)
CPU wakes, jumps to PROGADDR_IRQ
    ↓
uart_irq_handler() executes
    ↓
CPU can return to WFI or main code
```

---

## Backward Compatibility Notes

### Regression Testing
- ⚠️ **Testbenches referencing `gclk_spi`**: May need updating (not yet audited)
- ✅ **ROM/RAM address widths**: Updated to 16-bit for 64K capacity

### Configuration Changes
- PicoRV32 ENABLE_IRQ: Changed from 0 → 1
- CPU PROGADDR_IRQ: Already set to 0x10 (unchanged)
- Bus decoder: SPI now permanently disabled

---

## File Modifications Summary

| File | Change | Impact |
|------|--------|--------|
| `rtl/soc_top.v` | ROM ADDR_WIDTH: 14 → 16 | Fixes ROM capacity |
| `rtl/soc_top.v` | UART IRQ → CPU IRQ[0] | Enables interrupt path |
| `rtl/soc_top.v` | Removed SPI instance | Power optimization |
| `rtl/soc_top_asic.v` | Same as soc_top.v | ASIC variant sync |
| `rtl/cmu.v` | Removed SPI ICG | Reduces clock domains |
| `rtl/real_uart_mmio.v` | Added `irq_rx` output | Interrupt source |
| `fw/main.c` | Removed SPI code | Firmware cleanup |
| `fw/main.c` | Added ISR handler | Interrupt support |
| `fw/start.S` | Minimal startup | Standard RISC-V init |

---

## Next Steps

### Optional Enhancements
1. Add UART TX interrupt for full duplex interrupt-driven I/O
2. Implement proper ISR table for multiple interrupt sources
3. Add actual WFI instruction deployment code
4. Create complete low-power firmware demo with WFI loop

### Regression Testing
1. Audit all testbenches for `gclk_spi` references
2. Run full Phase 3 testbench suite
3. Verify synthesis with updated CMU clock gating

### Documentation
- [ ] Update ARCHITECTURE.md with new interrupt flow
- [ ] Document firmware ISR calling convention
- [ ] Add low-power operation guide for deployment
