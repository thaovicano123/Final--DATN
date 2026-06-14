#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THIRD_PARTY_DIR="$ROOT_DIR/third_party"
PICO_DIR="$THIRD_PARTY_DIR/picorv32"

mkdir -p "$THIRD_PARTY_DIR"

if [[ ! -d "$PICO_DIR" ]]; then
  echo "[INFO] Cloning PicoRV32..."
  git clone https://github.com/YosysHQ/picorv32.git "$PICO_DIR"
fi

cd "$PICO_DIR"

# Smoke test: run one of the provided test targets.
# If target names change upstream, run `make help` or inspect Makefile.
echo "[INFO] Running PicoRV32 testbench smoke test..."
TOOLCHAIN_PREFIX_OVERRIDE=""
if command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
  TOOLCHAIN_PREFIX_OVERRIDE="TOOLCHAIN_PREFIX=riscv64-unknown-elf-"
elif command -v riscv32-unknown-elf-gcc >/dev/null 2>&1; then
  TOOLCHAIN_PREFIX_OVERRIDE="TOOLCHAIN_PREFIX=riscv32-unknown-elf-"
else
  echo "[WARN] No RISC-V cross compiler found in PATH."
  echo "[WARN] Install riscv64-unknown-elf-gcc or riscv32-unknown-elf-gcc first."
  exit 1
fi

make test $TOOLCHAIN_PREFIX_OVERRIDE || {
  echo "[WARN] make test failed. Check Makefile targets and dependencies."
  exit 1
}

echo "[OK] Smoke test completed."
