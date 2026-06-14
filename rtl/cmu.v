module cmu (
    input  wire        clk,
    input  wire        resetn,
    input  wire        valid,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output wire        ready,
    output wire [31:0] rdata,
    output wire        gclk_uart,
    output wire        gclk_gpio,
    output wire [1:0]  clk_en_state
);
    reg [1:0] clk_en;
    reg [31:0] rdata_reg;
    reg ready_reg;
    reg req_seen;

    wire wr_en = valid && (|wstrb);
    wire rd_en = valid && !(|wstrb);
    wire [3:0] reg_word = addr[5:2];

    assign ready = ready_reg;
    assign rdata = rdata_reg;
    assign clk_en_state = clk_en;

    // Synchronous handshake with req_seen pulse protocol (matching RAM/ROM)
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            clk_en <= 2'b11;
            ready_reg <= 1'b0;
            req_seen <= 1'b0;
            rdata_reg <= 32'h0000_0000;
        end else begin
            ready_reg <= 1'b0;  // Default: ready not asserted
            
            // Clear burst state once master deasserts valid
            if (!valid)
                req_seen <= 1'b0;
            
            // Execute exactly once per valid burst
            if (valid && !req_seen) begin
                req_seen <= 1'b1;
                ready_reg <= 1'b1;  // Assert ready for exactly 1 cycle
                
                // Process write or read
                if (wr_en) begin
                    case (reg_word)
                        4'h0: begin
                            if (wstrb[0])
                                clk_en <= wdata[1:0];
                        end
                        default: begin
                        end
                    endcase
                end else begin  // rd_en
                    case (reg_word)
                        4'h0: rdata_reg <= {30'd0, clk_en};
                        4'h1: rdata_reg <= {30'd0, clk_en};
                        default: rdata_reg <= 32'h0000_0000;
                    endcase
                end
            end
        end
    end

    icg_cell u_icg_uart (
        .clk(clk),
        .resetn(resetn),
        .en(clk_en[0]),
        .test_en(1'b0),
        .gclk(gclk_uart)
    );
    icg_cell u_icg_gpio (
        .clk(clk),
        .resetn(resetn),
        .en(clk_en[1]),
        .test_en(1'b0),
        .gclk(gclk_gpio)
    );
endmodule
