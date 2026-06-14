# Phase 1 (Week 1-2): Environment and Fundamentals

## Target outcome
- Linux environment ready for digital design tasks
- RISC-V toolchain available
- Icarus Verilog + GTKWave working
- PicoRV32 simulation smoke test completed
- Basic understanding of memory interface and interrupts
- Basic understanding of clock gating concepts

## Tasks
1. Install base tools on Ubuntu
2. Install or prepare RISC-V GCC toolchain
3. Clone PicoRV32 and read README sections:
   - native memory interface or AXI4-Lite
   - interrupt signals
4. Run existing PicoRV32 testbench
5. Study low-power basics:
   - dynamic power relation: P_dyn = alpha * C * V^2 * f
   - why clock gating cuts switching activity

## Exit criteria (Definition of Done)
- You can run `iverilog` and `vvp` without errors
- You can open waveforms by `gtkwave`
- PicoRV32 sample simulation runs end-to-end
- You can explain where clock gating should be inserted in your SoC

## Risks and mitigations
- Risk: RISC-V toolchain install fails due to dependencies
  - Mitigation: start with simulation first, then add cross-compiler
- Risk: Trying to understand entire core at once
  - Mitigation: focus only on interfaces needed for integration
