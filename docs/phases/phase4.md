# Phase 4 (Week 10-12): ASIC Synthesis and Evaluation

## Target outcome
Gate-level synthesis reports with and without clock gating, and quantified power benefit.

## Tasks
1. Select technology/library flow:
   - commercial flow (Design Compiler + foundry lib), or
   - open-source flow (Yosys + Sky130)
2. Prepare synthesis scripts and constraints:
   - clocks, io delays, basic constraints
3. Run synthesis twice:
   - case A: no clock gating
   - case B: with clock gating
4. Collect reports:
   - power.rpt
   - area.rpt
   - timing.rpt
5. Compare dynamic and leakage power

## Memory scope decision for this project
1. Chosen method: blackbox ROM/RAM in synthesis runs for logic-domain comparison.
2. Functional simulation still uses inferred memory wrappers for firmware execution.
3. This keeps power comparison focused on CPU + interconnect + gated peripherals.

## Execution commands (Yosys)
1. `./scripts/run_phase4_clock_gating_compare.sh`
2. Cases:
   - Case A (no clock gating): `syn/yosys_phase4_no_gating.ys`
   - Case B (with clock gating): `syn/yosys_phase4_with_gating.ys`
3. Outputs:
   - `results/syn/phase4_no_gating/stat.txt`
   - `results/syn/phase4_with_gating/stat.txt`
   - `results/syn/phase4_no_gating/yosys.log`
   - `results/syn/phase4_with_gating/yosys.log`
   - `results/syn/phase4_compare_summary.md`

## Current verification scope
1. Structural synthesis comparison is automated and reproducible in open-source flow.
2. Memory is blackboxed in both cases to isolate logic-domain impact.
3. Technology-signoff power/timing numbers require liberty + full STA/power tools.

## Exit criteria
- Both synthesis runs complete
- Reports are archived in `results/`
- Comparison table is ready for thesis chapter and slides
