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
  rtl/real_uart_mmio.v
)

mkdir -p results/phase2

echo "[INFO] Building IRQ firmware..."
./scripts/build_fw_irq.sh

echo "[INFO] Compiling soc_top IRQ testbench..."
iverilog -g2012 -s tb_soc_top_irq -o results/phase2/tb_soc_top_irq.vvp \
  tb/tb_soc_top_irq.v "$PICO_RTL" "${COMMON_RTL[@]}"

echo "[INFO] Running soc_top IRQ simulation..."
vvp results/phase2/tb_soc_top_irq.vvp | tee results/phase2/tb_soc_top_irq.log

echo "[OK] Done."
echo "  - Log: results/phase2/tb_soc_top_irq.log"
echo "  - VCD: results/phase2/tb_soc_top_irq.vcd"
