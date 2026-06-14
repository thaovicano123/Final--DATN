#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v yosys >/dev/null 2>&1; then
    echo "[ERROR] yosys not found. Install yosys before running synthesis compare."
    exit 1
fi

mkdir -p results/syn/with_memory results/syn/blackbox_memory

echo "[INFO] Running Yosys flow: with inferred memory..."
yosys -s syn/yosys_with_memory.ys | tee results/syn/with_memory/yosys.log

echo "[INFO] Running Yosys flow: blackbox memory..."
yosys -s syn/yosys_blackbox_memory.ys | tee results/syn/blackbox_memory/yosys.log

echo ""
echo "[INFO] Synthesis compare completed."
echo "- With memory stat:      results/syn/with_memory/stat.txt"
echo "- Blackbox memory stat:  results/syn/blackbox_memory/stat.txt"
echo "- With memory netlist:   results/syn/with_memory/soc_top_netlist.v"
echo "- Blackbox netlist:      results/syn/blackbox_memory/soc_top_netlist.v"
echo ""
echo "[TIP] Use these files in Phase 4 to report logic-only power methodology."
