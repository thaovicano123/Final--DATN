# SoC Block Diagram (Phase 2)

```mermaid
flowchart LR
    CPU["PicoRV32 Core<br/>Native Memory IF"]
    DEC[Address Decoder / Interconnect]

    ROM["Inferred ROM<br/>0x0000_0000"]
    RAM["Inferred RAM<br/>0x1000_0000"]
    UART["UART MMIO<br/>0x2000_0000"]
    SPI["SPI MMIO<br/>0x2000_1000"]
    GPIO["GPIO MMIO<br/>0x2000_2000"]
    CMU["CMU + ICG<br/>0x2000_3000"]

    CLK[clk]
    RST[resetn]

    CPU --> DEC
    DEC --> ROM
    DEC --> RAM
    DEC --> UART
    DEC --> SPI
    DEC --> GPIO
    DEC --> CMU

    CLK --> CPU
    CLK --> CMU
    CLK --> RAM
    CMU -->|gated clk| UART
    CMU -->|gated clk| SPI
    CMU -->|gated clk| GPIO

    SPI -->|irq0| CPU
    RST --> CPU
    RST --> CMU
    RST --> RAM
    RST --> UART
    RST --> SPI
    RST --> GPIO
```

## Integration notes
- Native PicoRV32 memory interface is used for simpler student-friendly integration.
- ROM/RAM blocks are implemented as inferred memory models in this project flow.
- CMU is always on root clock so clock gating control registers stay accessible.
- UART/SPI/GPIO run on gated clocks from CMU ICG outputs.
