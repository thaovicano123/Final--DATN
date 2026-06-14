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
  echo "[ERROR] No RISC-V cross compiler found (riscv64-unknown-elf-gcc or riscv32-unknown-elf-gcc)."
  exit 1
fi

echo "[INFO] Building firmware with ${CC}"

${CC} -march=rv32im -mabi=ilp32 -Os -ffreestanding -nostdlib -nostartfiles \
  -Wl,-T,fw/linker.ld,-Map,fw/firmware.map,--build-id=none \
  -o fw/firmware.elf fw/start.S fw/main.c

${PREFIX}objcopy -O binary fw/firmware.elf fw/firmware.bin
python3 scripts/bin_to_hex32.py fw/firmware.bin fw/firmware.hex 16384

echo "[OK] Firmware generated:"
echo "  - fw/firmware.elf"
echo "  - fw/firmware.bin"
echo "  - fw/firmware.hex"
