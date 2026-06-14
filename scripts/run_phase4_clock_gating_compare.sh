#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v yosys >/dev/null 2>&1; then
    echo "[ERROR] yosys not found. Install yosys before running Phase4 synthesis compare."
    exit 1
fi

mkdir -p results/syn/phase4_no_gating results/syn/phase4_with_gating

echo "[INFO] Running Phase4 Case A (no clock gating)..."
yosys -s syn/yosys_phase4_no_gating.ys | tee results/syn/phase4_no_gating/yosys.log

echo "[INFO] Running Phase4 Case B (with clock gating)..."
yosys -s syn/yosys_phase4_with_gating.ys | tee results/syn/phase4_with_gating/yosys.log

extract_cells() {
    local stat_file="$1"
    awk '
        /Number of cells:/ {capture=1; next}
        capture && /^\s*\$/ {name=$1; count=$2; gsub(/^[[:space:]]+/, "", name); gsub(/^[[:space:]]+/, "", count); if (name=="$dff") dff=count; if (name=="$not") notc=count; if (name=="$mux") mux=count; if (name=="$and") andc=count; if (name=="$or") orc=count; if (name=="$xor") xorc=count; if (name=="$xnor") xnorc=count; total += count}
        END {
            if (dff=="") dff=0; if (notc=="") notc=0; if (mux=="") mux=0;
            if (andc=="") andc=0; if (orc=="") orc=0; if (xorc=="") xorc=0; if (xnorc=="") xnorc=0;
            if (total=="") total=0;
            printf "%s %s %s %s %s %s %s %s\n", total, dff, mux, andc, orc, xorc, xnorc, notc;
        }
    ' "$stat_file"
}

read -r total_a dff_a mux_a and_a or_a xor_a xnor_a not_a <<< "$(extract_cells results/syn/phase4_no_gating/stat.txt)"
read -r total_b dff_b mux_b and_b or_b xor_b xnor_b not_b <<< "$(extract_cells results/syn/phase4_with_gating/stat.txt)"

report_file="results/syn/phase4_compare_summary.md"
cat > "$report_file" <<EOF
# Phase4 Clock-Gating Synthesis Compare (Yosys)

| Metric | Case A: No Gating | Case B: With Gating |
|---|---:|---:|
| Total mapped cells (approx) | ${total_a} | ${total_b} |
| \$dff | ${dff_a} | ${dff_b} |
| \$mux | ${mux_a} | ${mux_b} |
| \$and | ${and_a} | ${and_b} |
| \$or | ${or_a} | ${or_b} |
| \$xor | ${xor_a} | ${xor_b} |
| \$xnor | ${xnor_a} | ${xnor_b} |
| \$not | ${not_a} | ${not_b} |

## Notes
- Memory blocks are blackboxed in both cases (`syn/mem_blackbox_cells.v`).
- This comparison isolates logic-structure impact of clock-gating architecture.
- For sign-off power numbers, replace with technology libraries and run full STA + power flow.
EOF

echo "[OK] Phase4 synthesis compare completed."
echo "  - Case A stat: results/syn/phase4_no_gating/stat.txt"
echo "  - Case B stat: results/syn/phase4_with_gating/stat.txt"
echo "  - Summary:     ${report_file}"
