# Memory Strategy: Inferred ROM/RAM (Academic Flow)

## Decision
This project uses inferred memory models for ROM and RAM instead of enterprise memory compiler macros.

Selected for Phase 4 power methodology:
- Simulation: inferred memory models (`soc_rom`, `soc_ram`) are used for full functional verification.
- Synthesis/power comparison: memory is treated as blackbox to isolate logic-domain optimization impact.

## Why this is suitable for this project
1. The project objective is functional SoC integration and low-power behavior verification at RTL.
2. Access to foundry memory macros/compilers is typically limited in student environments.
3. Inferred models enable complete simulation, firmware bring-up, and interrupt verification.

## Implemented modules
- `rtl/soc_rom.v`: inferred ROM with optional hex preload via `MEMFILE`.
- `rtl/soc_ram.v`: inferred byte-write RAM (macro-friendly interface).

## What is validated with this approach
1. CPU-to-memory functional access.
2. Firmware execution from ROM image.
3. Data memory read/write behavior.
4. System-level integration with MMIO and IRQ paths.

## Limitations (to state in report)
1. This does not represent sign-off silicon memory implementation.
2. Timing/area/power of inferred memory is not equal to foundry SRAM/ROM macros.
3. Final ASIC flow should replace wrappers with technology memory macros.

## Migration path to enterprise flow
1. Keep bus-level interface unchanged in `soc_top`.
2. Replace internals of `soc_rom` / `soc_ram` wrappers with macro instantiation.
3. Re-run synthesis and power analysis for final ASIC numbers.

## Blackbox synthesis flow (selected)
1. Blackbox stubs are defined in `syn/mem_blackbox_cells.v`.
2. Full synthesis script: `syn/yosys_with_memory.ys`.
3. Logic-only synthesis script: `syn/yosys_blackbox_memory.ys`.
4. One-command runner: `scripts/run_synth_compare.sh`.
