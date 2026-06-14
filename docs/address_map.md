# SoC Address Map (Phase 3 - Post SPI Removal)

| Region | Base Address | Size | Description |
|---|---:|---:|---|
| ROM | `0x0000_0000` | 64 KB | Inferred ROM model (firmware image preload) |
| RAM | `0x1000_0000` | 64 KB | Inferred RAM model (byte-write data memory) |
| UART | `0x2000_0000` | 4 KB | UART MMIO registers |
| GPIO | `0x2000_2000` | 4 KB | GPIO MMIO registers |
| CMU | `0x2000_3000` | 4 KB | Clock management + clock gating control |

## Memory implementation note
- Current ROM/RAM are inferred memory wrappers for academic RTL verification.
- In enterprise ASIC flow, these wrappers are intended to be replaced with foundry memory macros.
- **SPI peripheral has been removed** (Phase 3 optimization for low-power UART IRQ operation).

## Peripheral register map (Phase 3 Updated)

### UART (`0x2000_0000`)
- `0x00` TXDATA (W): write byte to transmit
- `0x04` STATUS (R): bit0 = tx_ready (always 1 in current model)
- `0x08` RXDATA (R): bit[31] = valid flag (auto-clear on read), bit[7:0] = received byte

### GPIO (`0x2000_2000`)
- `0x00` DATA_OUT (RW): output register
- `0x04` DATA_IN (R): input state
- `0x08` DIR (RW): 1=output, 0=input
- `0x0C` TOGGLE (W): toggle selected output bits

### CMU (`0x2000_3000`)
- `0x00` CLK_EN (RW): 2-bit clock enable register
  - bit[0] = UART clock enable (`gclk_uart`)
  - bit[1] = GPIO clock enable (`gclk_gpio`)
- `0x04` CLK_STAT (R): latched enables (same as CLK_EN in this model)

## Clock Gating Domains
| Domain | Control Bit | Signal | Status |
|--------|-------------|--------|--------|
| UART | CLK_EN[0] | `gclk_uart` | ✅ Active (2-bit) |
| GPIO | CLK_EN[1] | `gclk_gpio` | ✅ Active (2-bit) |
| SPI | - | - | ❌ Removed (Phase 3) |
