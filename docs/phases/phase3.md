# Phase 3 (Week 7-9): Firmware and Simulation

## Target outcome
Firmware drives SoC functions and verifies low-power behavior in simulation.

## Tasks
1. Write C firmware:
   - UART init and hello print
   - GPIO toggle
   - spi interrupt configuration
2. Build firmware to `.hex`
3. Write SoC testbench:
   - clock/reset generation
   - ROM preload from hex
   - simulation runtime control
4. Run simulation and inspect waveform:
   - verify functional correctness
   - verify gated clocks stay low when disabled

## Exit criteria
- Hello output is visible in simulation log/UART model
- GPIO/SPI behavior matches expectation
- Waveform evidence for clock gating is captured
