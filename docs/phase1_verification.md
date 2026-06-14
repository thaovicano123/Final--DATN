# Phase 1 Verification Report

Date: 2026-04-18

## Verification commands executed
1. Tool installation:
   - `sudo apt update`
   - `sudo apt install -y git make gcc g++ python3 iverilog gtkwave gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf`
2. Tool presence check:
   - `command -v make`
   - `command -v iverilog`
   - `command -v vvp`
   - `command -v gtkwave`
   - `command -v riscv64-unknown-elf-gcc`
3. Simulation smoke test:
   - `make test TOOLCHAIN_PREFIX=riscv64-unknown-elf-`
4. Waveform generation:
   - `make test_vcd TOOLCHAIN_PREFIX=riscv64-unknown-elf-`
5. Archived logs:
   - `results/phase1/make_test.log`
   - `results/phase1/make_test_vcd.log`

## Results summary
- Toolchain and simulation tools: PASS
- PicoRV32 sample simulation: PASS
- Waveform artifact generation: PASS
- Interface/IRQ understanding notes: PASS (see `docs/notes_picorv32_interfaces.md`)

## Key observed evidence
- Simulation output includes `ALL TESTS PASSED.`
- Waveform generation output includes `VCD info: dumpfile testbench.vcd opened for output.`
- Generated artifacts:
  - `third_party/picorv32/testbench.vcd`
  - `third_party/picorv32/testbench.trace`
  - `third_party/picorv32/firmware/firmware.hex`
   - `results/phase1/make_test.log`
   - `results/phase1/make_test_vcd.log`

## Note on toolchain path
- Upstream Makefile defaults to `/opt/riscv32i/bin/riscv32-unknown-elf-`.
- In this environment, Debian/Ubuntu package provides `riscv64-unknown-elf-*` binaries.
- Running with `TOOLCHAIN_PREFIX=riscv64-unknown-elf-` works for RV32 build flags (`-march=rv32*`, `-mabi=ilp32`).

## DoD mapping against Phase 1
- Can run `iverilog` and `vvp` without errors: PASS
- Can open waveforms by `gtkwave`: PASS (tool installed, VCD generated)
- PicoRV32 sample simulation runs end-to-end: PASS
- Can explain where clock gating should be inserted in SoC: PASS (peripheral clocks in UART/SPI/GPIO via CMU)

## Conclusion
Phase 1 is complete.
