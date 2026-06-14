# Clock Gating Policy (Phase 2)

## Objective
Reduce dynamic power by disabling peripheral clocks when blocks are idle.

## Policy
- CPU clock: always on in Phase 2 baseline.
- UART clock: controlled by `CMU.CLK_EN[0]`.
- SPI clock: controlled by `CMU.CLK_EN[1]`.
- GPIO clock: controlled by `CMU.CLK_EN[2]`.

## Reset behavior
- After reset, all peripheral gates default enabled (`CLK_EN = 3'b111`) for easy bring-up/debug.
- Firmware can disable unused blocks at runtime.

## Safety notes
- CMU logic and control registers are on ungated root clock.
- ICG cell uses latch-based enable sampling while input clock is low.
- Peripheral state is retained while clock is gated; activity pauses.

## Verification checklist
- Write `CMU.CLK_EN` bit = 0 -> corresponding gated clock stops toggling.
- Write bit = 1 -> gated clock resumes toggling.
- UART/SPI/GPIO register activity should pause while their clocks are gated.
