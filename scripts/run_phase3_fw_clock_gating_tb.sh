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

mkdir -p results/phase3

echo "[INFO] Building clock-gating firmware..."
./scripts/build_fw_gating.sh

echo "[INFO] Compiling phase3 firmware clock-gating testbench..."
iverilog -g2012 -s tb_phase3_fw_clock_gating -o results/phase3/tb_phase3_fw_clock_gating.vvp \
  tb/tb_phase3_fw_clock_gating.v "$PICO_RTL" "${COMMON_RTL[@]}"

echo "[INFO] Running phase3 firmware clock-gating simulation..."
vvp results/phase3/tb_phase3_fw_clock_gating.vvp | tee results/phase3/tb_phase3_fw_clock_gating.log

echo "[OK] Done."
echo "  - Log: results/phase3/tb_phase3_fw_clock_gating.log"
echo "  - VCD: results/phase3/tb_phase3_fw_clock_gating.vcd"
