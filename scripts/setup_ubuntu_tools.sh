#!/usr/bin/env bash
set -euo pipefail

# Basic packages for simulation and development
sudo apt update
sudo apt install -y \
  git make gcc g++ python3 \
  iverilog gtkwave

echo "[OK] Base tools installed."
echo "Next: clone PicoRV32 and run smoke test script."
