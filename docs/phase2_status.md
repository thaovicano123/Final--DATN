# Phase 2 Status (Current Snapshot)

## Implemented RTL modules
- `rtl/soc_top.v`
- `rtl/bus_decoder.v`
- `rtl/cmu.v`
- `rtl/icg_cell.v`
- `rtl/soc_rom.v`
- `rtl/soc_ram.v`
- `rtl/uart_mmio.v`
- `rtl/spi_mmio.v`
- `rtl/gpio_mmio.v`

## Implemented verification and build scripts
- `scripts/check_phase2_rtl.sh`
- `scripts/run_phase2_tb.sh`
- `scripts/build_fw.sh`
- `scripts/bin_to_hex32.py`
- `scripts/run_soc_top_smoke.sh`
- `scripts/build_fw_irq.sh`
- `scripts/run_phase3_irq_tb.sh`

## Architecture artifacts
- `docs/block_diagram.md`
- `docs/address_map.md`
- `docs/clock_gating_policy.md`
- `docs/memory_model_strategy.md`

## Memory implementation choice
1. ROM/RAM are implemented as inferred memory models (`rtl/soc_rom.v`, `rtl/soc_ram.v`).
2. This choice is intentional for academic RTL verification where enterprise memory macros are unavailable.
3. Wrapper interfaces are macro-ready to support later replacement in ASIC flow.

## What is completed vs. phase-2 tasks
1. Block diagram: completed
2. Address decoder/interconnect: completed
3. CMU + ICG for UART/SPI/GPIO: completed
4. Top-level SoC wrapper integration: completed

## Verification done
- Syntax/integration compilation passed with:
  - `iverilog -g2012 -o /tmp/soc_phase2_check.vvp third_party/picorv32/picorv32.v rtl/*.v`
- No VS Code RTL errors reported for `rtl/`.
- Automated phase-2 functional testbench passed:
  - Run: `./scripts/run_phase2_tb.sh`
  - Result marker: `PHASE2 TESTBENCH RESULT: PASS`
  - Log: `results/phase2/tb_phase2_mmio_irq_gating.log`
  - Waveform: `results/phase2/tb_phase2_mmio_irq_gating.vcd`
- CPU-integrated SoC smoke test passed:
  - Run: `./scripts/run_soc_top_smoke.sh`
  - Firmware image: `fw/firmware.hex`
  - Result marker: `SOC_TOP_SMOKE: PASS`
  - Log: `results/phase2/tb_soc_top_smoke.log`
  - Waveform: `results/phase2/tb_soc_top_smoke.vcd`
- CPU-integrated IRQ flow test passed:
  - Firmware: `fw/firmware_irq.hex`
  - Run: `./scripts/run_phase3_irq_tb.sh`
  - Result marker: `SOC_TOP_IRQ: PASS`
  - Log: `results/phase2/tb_soc_top_irq.log`
  - Waveform: `results/phase2/tb_soc_top_irq.vcd`

## Test coverage in phase-2 testbench
1. MMIO read/write:
  - GPIO DATA_OUT, GPIO TOGGLE, GPIO DATA_IN
  - UART TXDATA write/readback model
2. SPI IRQ:
  - SPI configuration
  - IRQ assertion check
  - IRQ status check and clear flow
3. Clock gating verification:
  - Initial enabled clock activity
  - Disabled clock no-steady-toggle behavior
  - Selective re-enable behavior per peripheral
4. CPU+MMIO integration smoke:
  - PicoRV32 executes firmware from ROM image
  - Firmware writes UART text output
  - Firmware toggles GPIO in a loop
5. CPU+IRQ integration smoke:
  - SPI IRQ configured by firmware
  - IRQ vector at `0x00000010` executes custom `retirq` flow
  - ISR toggles GPIO bit[8] and clears SPI pending status

## Next optimization-focused actions
1. Add SoC-level testbench in `tb/` for MMIO and IRQ behavior.
2. Add waveform checks proving gated clocks stop when CMU bits are cleared.
3. Add simple firmware for this address map to drive UART/GPIO/SPI end-to-end.
4. Run lint (if available) and clean up any style/synthesis warnings.
