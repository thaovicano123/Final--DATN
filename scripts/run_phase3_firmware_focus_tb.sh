#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p results/phase3

echo "[INFO] Building IRQ firmware (for firmware-focused test)..."
./scripts/build_fw_irq.sh

echo "[INFO] Compiling phase3 firmware-focused testbench..."
iverilog -g2012 -o results/phase3/tb_phase3_firmware_focus.vvp \
  tb/tb_phase3_firmware_focus.v third_party/picorv32/picorv32.v rtl/*.v

echo "[INFO] Running phase3 firmware-focused simulation..."
vvp results/phase3/tb_phase3_firmware_focus.vvp | tee results/phase3/tb_phase3_firmware_focus.log

echo "[OK] Done."
echo "  - Log: results/phase3/tb_phase3_firmware_focus.log"
echo "  - VCD: results/phase3/tb_phase3_firmware_focus.vcd"
