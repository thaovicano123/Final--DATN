# Phase4 Clock-Gating Synthesis Compare (Yosys)

| Metric | Case A: No Gating | Case B: With Gating |
|---|---:|---:|
| Total mapped cells (approx) | 24492 | 24504 |
| $dff | 0 | 0 |
| $mux | 0 | 0 |
| $and | 0 | 0 |
| $or | 0 | 0 |
| $xor | 0 | 0 |
| $xnor | 0 | 0 |
| $not | 0 | 0 |

## Notes
- Memory blocks are blackboxed in both cases ().
- This comparison isolates logic-structure impact of clock-gating architecture.
- For sign-off power numbers, replace with technology libraries and run full STA + power flow.
