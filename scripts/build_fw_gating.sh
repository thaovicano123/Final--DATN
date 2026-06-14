#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

CC=""
PREFIX=""

if command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
  CC="riscv64-unknown-elf-gcc"
  PREFIX="riscv64-unknown-elf-"
elif command -v riscv32-unknown-elf-gcc >/dev/null 2>&1; then
  CC="riscv32-unknown-elf-gcc"
  PREFIX="riscv32-unknown-elf-"
else
  echo "[ERROR] No RISC-V cross compiler found."
  exit 1
fi

echo "[INFO] Building clock-gating firmware with ${CC}"

${CC} -march=rv32im -mabi=ilp32 -Os -ffreestanding -nostdlib -nostartfiles \
  -Wl,-T,fw/linker.ld,-Map,fw/firmware_gating.map,--build-id=none \
  -o fw/firmware_gating.elf fw/start.S fw/main_gating.c

${PREFIX}objcopy -O binary fw/firmware_gating.elf fw/firmware_gating.bin
python3 scripts/bin_to_hex32.py fw/firmware_gating.bin fw/firmware_gating.hex 16384

echo "[OK] Clock-gating firmware generated:"
echo "  - fw/firmware_gating.elf"
echo "  - fw/firmware_gating.bin"
echo "  - fw/firmware_gating.hex"
