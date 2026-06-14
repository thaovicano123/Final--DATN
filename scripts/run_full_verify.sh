#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p results/phase2 results/phase3

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

UNIT_RESULTS=()
INTEG_RESULTS=()
FAIL_COUNT=0

run_case() {
  local group="$1"
  local name="$2"
  local top="$3"
  local out_dir="$4"
  shift 4

  local vvp_path="results/${out_dir}/${name}.vvp"
  local log_path="results/${out_dir}/${name}.log"

  echo "[INFO] Compiling ${name}..."
  if ! iverilog -g2012 -s "$top" -o "$vvp_path" "$@" >"$log_path" 2>&1; then
    echo "[FAIL] Compile failed: ${name}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    if [[ "$group" == "unit" ]]; then
      UNIT_RESULTS+=("${name}:FAIL")
    else
      INTEG_RESULTS+=("${name}:FAIL")
    fi
    return
  fi

  echo "[INFO] Running ${name}..."
  if ! vvp "$vvp_path" >>"$log_path" 2>&1; then
    echo "[FAIL] Simulation failed: ${name}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    if [[ "$group" == "unit" ]]; then
      UNIT_RESULTS+=("${name}:FAIL")
    else
      INTEG_RESULTS+=("${name}:FAIL")
    fi
    return
  fi

  echo "[PASS] ${name}"
  if [[ "$group" == "unit" ]]; then
    UNIT_RESULTS+=("${name}:PASS")
  else
    INTEG_RESULTS+=("${name}:PASS")
  fi
}

print_summary() {
  local label="$1"
  shift
  echo ""
  echo "===== ${label} ====="
  if [[ "$#" -eq 0 ]]; then
    echo "(none)"
    return
  fi
  for item in "$@"; do
    echo "$item"
  done
}

echo "[INFO] Building firmware images..."
./scripts/build_fw.sh
./scripts/build_fw_irq.sh
./scripts/build_fw_gating.sh

echo "[INFO] Running unit testbenches (explicit file lists, no wildcard)..."
run_case unit tb_picorv32 tb_picorv32 phase3 tb/tb_picorv32.v "$PICO_RTL"
run_case unit tb_real_uart_mmio tb_real_uart_mmio phase3 tb/tb_real_uart.v rtl/real_uart_mmio.v
run_case unit tb_rom tb_rom phase3 tb/tb_rom.v rtl/soc_rom.v
run_case unit tb_ram tb_ram phase3 tb/tb_ram.v rtl/soc_ram.v
run_case unit tb_gpio tb_gpio phase3 tb/tb_gpio.v rtl/gpio_mmio.v
run_case unit tb_decoder tb_decoder phase3 tb/tb_decoder.v rtl/bus_decoder.v
run_case unit tb_cmu tb_cmu phase3 tb/tb_cmu.v rtl/cmu.v rtl/icg_cell.v

echo "[INFO] Running integration testbenches (explicit file lists, no wildcard)..."
run_case integration tb_soc_top_smoke tb_soc_top_smoke phase2 tb/tb_soc_top_smoke.v "$PICO_RTL" "${COMMON_RTL[@]}"
run_case integration tb_soc_top_irq tb_soc_top_irq phase2 tb/tb_soc_top_irq.v "$PICO_RTL" "${COMMON_RTL[@]}"
run_case integration tb_phase2_mmio_irq_gating tb_phase2_mmio_irq_gating phase2 tb/tb_phase2_mmio_irq_gating.v "$PICO_RTL" "${COMMON_RTL[@]}"
run_case integration tb_phase3_firmware_focus tb_phase3_firmware_focus phase3 tb/tb_phase3_firmware_focus.v "$PICO_RTL" "${COMMON_RTL[@]}"
run_case integration tb_phase3_fw_clock_gating tb_phase3_fw_clock_gating phase3 tb/tb_phase3_fw_clock_gating.v "$PICO_RTL" "${COMMON_RTL[@]}"

print_summary "UNIT" "${UNIT_RESULTS[@]}"
print_summary "INTEGRATION" "${INTEG_RESULTS[@]}"

echo ""
echo "[INFO] Logs are in results/phase2 and results/phase3"

if [[ "$FAIL_COUNT" -ne 0 ]]; then
  echo "[FAIL] Full verify completed with ${FAIL_COUNT} failure(s)."
  exit 1
fi

echo "[OK] Full verify completed successfully."
