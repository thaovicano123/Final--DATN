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

echo "[INFO] Building firmware..."
./scripts/build_fw.sh

echo "[INFO] Compiling soc_top smoke testbench..."
iverilog -g2012 -s tb_soc_top_smoke -o results/phase2/tb_soc_top_smoke.vvp \
  tb/tb_soc_top_smoke.v "$PICO_RTL" "${COMMON_RTL[@]}"

echo "[INFO] Running soc_top smoke simulation..."
vvp results/phase2/tb_soc_top_smoke.vvp | tee results/phase2/tb_soc_top_smoke.log

echo "[OK] Done."
echo "  - Log: results/phase2/tb_soc_top_smoke.log"
echo "  - VCD: results/phase2/tb_soc_top_smoke.vcd"
