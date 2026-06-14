#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

PICO_RTL="third_party/picorv32/picorv32.v"
COMMON_RTL=(
	rtl/bus_decoder.v
	rtl/cmu.v
	rtl/gpio_mmio.v
	rtl/icg_cell.v
	rtl/soc_ram.v
	rtl/soc_rom.v
	rtl/soc_top.v
	rtl/soc_top_asic.v
	rtl/real_uart_mmio.v
)

echo "[INFO] Compiling Phase-2 RTL with PicoRV32..."
iverilog -g2012 -o /tmp/soc_phase2_check.vvp "$PICO_RTL" "${COMMON_RTL[@]}"

echo "[OK] RTL syntax/integration check passed."
