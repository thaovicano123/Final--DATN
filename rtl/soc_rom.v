/// sta-blackbox
module soc_rom #(
    parameter MEMFILE    = "",
    parameter ADDR_WIDTH = 14,
    parameter INIT_NOP   = 1
) (
    input  wire        clk,
    input  wire        valid,
    input  wire [31:0] addr,
    output wire        ready,
    output wire [31:0] rdata
);

    // If USE_OPENRAM is defined, treat this module as a wrapper
    // so the OpenRAM-generated macro can be linked in during P&R.
`ifdef USE_OPENRAM
    // Instantiate the actual OpenRAM macro cell (output_name = soc_rom_2kb)
    // Apply same req_seen handshake protocol for timing consistency with simulation model
    wire [31:0] macro_dout;
    reg req_seen;
    reg ready_reg;
    
    soc_rom_2kb u_macro (
        .clk0(clk),
        .csb0(~valid),
        .web0(1'b1),        // Never write (Tie high)
        .wmask0(4'b0000),    // No write mask
        .addr0(addr[ADDR_WIDTH-1:0]),
        .din0(32'h0),
        .dout0(macro_dout)
    );
    
    reg [31:0] rdata_reg;
    
    always @(posedge clk) begin
        ready_reg <= 1'b0;  // Default: ready not asserted
        
        // Clear burst state once master deasserts valid
        if (!valid)
            req_seen <= 1'b0;
        
        // Execute exactly once per valid burst (matches simulation model)
        if (valid && !req_seen) begin
            req_seen <= 1'b1;
            ready_reg <= 1'b1;  // Assert ready for exactly 1 cycle
            rdata_reg <= macro_dout;  // Capture OpenRAM output
        end
    end
    
    assign ready = ready_reg;
    assign rdata = rdata_reg;
`else
    localparam DEPTH = (1 << ADDR_WIDTH);

    reg [31:0] mem [0:DEPTH-1];

    wire [ADDR_WIDTH-1:0] word_addr = addr[ADDR_WIDTH+1:2];

    // Synchronous ROM handshake with pulse protocol (matching RAM):
    // Executes exactly once per valid burst using req_seen flag.
    // This prevents unnecessary register flipping and power waste.
    reg        ready_reg;
    reg [31:0] rdata_reg;
    reg        req_seen;

    always @(posedge clk) begin
        ready_reg <= 1'b0;  // Default: ready not asserted
        
        // Clear burst state once master deasserts valid
        if (!valid)
            req_seen <= 1'b0;
        
        // Execute exactly once for each contiguous valid burst
        if (valid && !req_seen) begin
            req_seen <= 1'b1;
            ready_reg <= 1'b1;  // Assert ready for exactly 1 cycle
            rdata_reg <= mem[word_addr];  // Capture data only when processing request
        end
    end

    assign ready = ready_reg;
    assign rdata = rdata_reg;

    // Inferred ROM model for academic/project use.
    // This wrapper can be replaced by a foundry ROM macro in ASIC flow.
    integer i;
    initial begin
        if (INIT_NOP) begin
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] = 32'h0000_0013; // NOP (addi x0, x0, 0)
        end

        if (MEMFILE != "")
            $readmemh(MEMFILE, mem);
    end
`endif
endmodule