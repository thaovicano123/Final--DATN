# Task Guide: Read PicoRV32 README (Memory Interface, AXI4-Lite, Interrupt)

## Purpose
This task is for integration understanding, not RTL optimization.
You read and extract interface behavior so you can connect PicoRV32 correctly in your SoC.

## Scope to read
1. Native memory interface section
2. AXI4-Lite related module choices
3. Interrupt architecture and IRQ custom instructions

## Step-by-step actions
1. Clone repository (done once):
```bash
cd /home/thaonguyen/Final/third_party
git clone https://github.com/YosysHQ/picorv32.git
```
2. Open README and read these sections first:
   - "PicoRV32 Native Memory Interface"
   - "Custom Instructions for IRQ Handling"
   - module list describing `picorv32`, `picorv32_axi`, `picorv32_axi_adapter`
3. Write a one-page note containing:
   - handshake timing of `mem_valid` / `mem_ready`
   - meaning of `mem_wstrb` byte enables
   - when to choose `picorv32` vs `picorv32_axi`
   - meaning of `irq` input and `eoi` output
   - which IRQ sources are internal (0/1/2)
4. Decide integration option for your SoC draft:
   - Option A (recommended for student project): native interface + simple address decoder
   - Option B: AXI4-Lite fabric via `picorv32_axi` or `picorv32_axi_adapter`
5. Record design decision in `docs/address_map.md` and `docs/clock_gating_policy.md`.

## What you should extract (minimum)
- Native interface is single-transaction valid/ready protocol:
  - request starts with `mem_valid`
  - transfer completes when slave asserts `mem_ready`
  - read: `mem_wstrb = 0`
  - write: `mem_wstrb != 0`
- AXI path options:
  - `picorv32_axi`: CPU with AXI4-Lite master interface
  - `picorv32_axi_adapter`: bridge native memory interface to AXI4-Lite
- IRQ essentials:
  - 32-bit `irq` input bitmap
  - `eoi` indicates end of serviced interrupt(s)
  - built-in IRQs include SPI (SoC-level), illegal/ebreak/ecall, bus error

## Deliverables for this task
- `docs/notes_picorv32_interfaces.md` (your notes)
- Updated `docs/address_map.md` draft
- Updated `docs/clock_gating_policy.md` draft

## Done criteria
- You can explain one full read and one full write cycle on native interface.
- You can justify why your project uses native interface or AXI4-Lite.
- You can describe how IRQ enters CPU and where firmware handles it.

## Common misunderstanding
"Reading these sections" is not RTL optimization.
It is architecture/interface comprehension before writing RTL.
Real optimization comes later (clock gating insertion, synthesis constraints, timing/power iterations).
