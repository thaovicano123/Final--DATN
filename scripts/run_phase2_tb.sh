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

echo "[INFO] Building Phase 2 testbench..."
iverilog -g2012 -s tb_phase2_mmio_irq_gating -o results/phase2/tb_phase2_mmio_irq_gating.vvp \
  tb/tb_phase2_mmio_irq_gating.v "$PICO_RTL" "${COMMON_RTL[@]}"

echo "[INFO] Running Phase 2 testbench..."
vvp results/phase2/tb_phase2_mmio_irq_gating.vvp | tee results/phase2/tb_phase2_mmio_irq_gating.log

echo "[OK] Done."
echo "  - Log: results/phase2/tb_phase2_mmio_irq_gating.log"
echo "  - VCD: results/phase2/tb_phase2_mmio_irq_gating.vcd"
