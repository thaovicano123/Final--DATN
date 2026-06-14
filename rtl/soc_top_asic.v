// ============================================================================
// Module: soc_top_asic (LibreLane SoC — ASIC Hardening Variant)
// Giống soc_top nhưng không truyền parameter cho ROM/RAM — tương thích OpenLane.
// ============================================================================
module soc_top_asic #(
    parameter MEMFILE = ""
) (
    input  wire        clk,
    input  wire        resetn,
    input  wire        uart_rx,
    output wire        uart_tx,
    input  wire [31:0] gpio_in,
    output wire [31:0] gpio_out
);
    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_rdata;

    wire [31:0] irq;
    wire uart_irq;

    wire sel_rom;
    wire sel_ram;
    wire sel_uart;
    wire sel_gpio;
    wire sel_cmu;
    wire sel_none;

    wire rom_ready;
    wire [31:0] rom_rdata;
    wire ram_ready;
    wire [31:0] ram_rdata;
    wire uart_ready;
    wire [31:0] uart_rdata;
    wire gpio_ready;
    wire [31:0] gpio_rdata;
    wire cmu_ready;
    wire [31:0] cmu_rdata;

    wire gclk_uart;
    wire gclk_gpio;
    wire [1:0] clk_en_state;

    // Gated-clock access protection
    wire uart_clk_gated = ~clk_en_state[0];
    wire gpio_clk_gated = ~clk_en_state[1];

    // Route UART IRQ to CPU IRQ[0]
    assign irq = {31'd0, uart_irq};

    bus_decoder u_bus_decoder (
        .addr(mem_addr),
        .sel_rom(sel_rom),
        .sel_ram(sel_ram),
        .sel_uart(sel_uart),
        .sel_gpio(sel_gpio),
        .sel_cmu(sel_cmu),
        .sel_none(sel_none)
    );

    // ---- Bus Ready MUX (one-hot) ----
    assign mem_ready = (sel_rom   & rom_ready)  |
                       (sel_ram   & ram_ready)  |
                       (sel_uart  & (uart_clk_gated ? mem_valid : uart_ready)) |
                       (sel_gpio  & (gpio_clk_gated ? mem_valid : gpio_ready)) |
                       (sel_cmu   & cmu_ready)  |
                       (sel_none  & mem_valid);

    // ---- Bus Data MUX (one-hot, bus error signature) ----
    wire [31:0] uart_rdata_safe = uart_clk_gated ? 32'h0 : uart_rdata;
    wire [31:0] gpio_rdata_safe = gpio_clk_gated ? 32'h0 : gpio_rdata;

    assign mem_rdata = ({32{sel_rom}}  & rom_rdata)       |
                       ({32{sel_ram}}  & ram_rdata)       |
                       ({32{sel_uart}} & uart_rdata_safe) |
                       ({32{sel_gpio}} & gpio_rdata_safe) |
                       ({32{sel_cmu}}  & cmu_rdata)       |
                       ({32{sel_none}} & 32'hDEAD_DEAD);

    picorv32 #(
        .PROGADDR_RESET(32'h0000_0000),
        .PROGADDR_IRQ  (32'h0000_0010),
        .ENABLE_IRQ    (1),
        .ENABLE_IRQ_QREGS(1)
    ) u_cpu (
        .clk      (clk),
        .resetn   (resetn),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr (mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .irq      (irq)
    );

    // ROM: 1KB (ADDR_WIDTH=8)
    soc_rom #(
        .ADDR_WIDTH(8)
    ) u_rom (
        .clk  (clk),
        .valid(mem_valid && sel_rom),
        .addr (mem_addr),
        .ready(rom_ready),
        .rdata(rom_rdata)
    );

    // RAM: 256 Bytes (ADDR_WIDTH=6)
    soc_ram #(
        .ADDR_WIDTH(6)
    ) u_ram (
        .clk  (clk),
        .resetn(resetn),
        .valid(mem_valid && sel_ram),
        .addr (mem_addr),
        .wdata(mem_wdata),
        .wstrb(mem_wstrb),
        .ready(ram_ready),
        .rdata(ram_rdata)
    );

    cmu u_cmu (
        .clk  (clk),
        .resetn(resetn),
        .valid(mem_valid && sel_cmu),
        .addr (mem_addr),
        .wdata(mem_wdata),
        .wstrb(mem_wstrb),
        .ready(cmu_ready),
        .rdata(cmu_rdata),
        .gclk_uart(gclk_uart),
        .gclk_gpio(gclk_gpio),
        .clk_en_state(clk_en_state)
    );

    real_uart_mmio u_uart (
        .clk  (gclk_uart),
        .resetn(resetn),
        .valid(mem_valid && sel_uart),
        .addr (mem_addr),
        .wdata(mem_wdata),
        .wstrb(mem_wstrb),
        .ready(uart_ready),
        .rdata(uart_rdata),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx),
        .irq_rx(uart_irq)
    );

    gpio_mmio u_gpio (
        .clk  (gclk_gpio),
        .resetn(resetn),
        .valid(mem_valid && sel_gpio),
        .addr (mem_addr),
        .wdata(mem_wdata),
        .wstrb(mem_wstrb),
        .ready(gpio_ready),
        .rdata(gpio_rdata),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out)
    );
endmodule