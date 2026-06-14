/// sta-blackbox
// ============================================================================
// Module: gpio_mmio (Registered Output, req_seen Handshake)
// Mô tả: GPIO 32-bit với giao thức bus nhất quán với toàn hệ thống.
// Đặc điểm:
//   1. req_seen pulse protocol — đồng nhất với RAM/ROM/CMU.
//   2. Registered rdata output — tránh combinational path dài qua bus MUX.
//   3. Byte-enable write (wstrb) chuẩn RISC-V.
// ============================================================================
module gpio_mmio (
    input  wire        clk,
    input  wire        resetn,
    input  wire        valid,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output wire        ready,
    output wire [31:0] rdata,
    input  wire [31:0] gpio_in,
    output wire [31:0] gpio_out
);
    reg [31:0] data_out_reg;
    reg [31:0] dir_reg;

    // Registered bus handshake (consistent with RAM/ROM/CMU)
    reg        ready_reg;
    reg [31:0] rdata_reg;
    reg        req_seen;

    wire [3:0] reg_word = addr[5:2];

    assign ready    = ready_reg;
    assign rdata    = rdata_reg;
    assign gpio_out = data_out_reg & dir_reg;

    function [31:0] apply_wstrb;
        input [31:0] old_val;
        input [31:0] new_val;
        input [3:0]  be;
        begin
            apply_wstrb = old_val;
            if (be[0]) apply_wstrb[7:0]   = new_val[7:0];
            if (be[1]) apply_wstrb[15:8]  = new_val[15:8];
            if (be[2]) apply_wstrb[23:16] = new_val[23:16];
            if (be[3]) apply_wstrb[31:24] = new_val[31:24];
        end
    endfunction

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            data_out_reg <= 32'h0000_0000;
            dir_reg      <= 32'h0000_0000;
            ready_reg    <= 1'b0;
            rdata_reg    <= 32'h0000_0000;
            req_seen     <= 1'b0;
        end else begin
            ready_reg <= 1'b0;  // Default: ready not asserted

            // Clear burst state once master deasserts valid
            if (!valid)
                req_seen <= 1'b0;

            // Execute exactly once per valid burst (matching RAM/ROM/CMU)
            if (valid && !req_seen) begin
                req_seen  <= 1'b1;
                ready_reg <= 1'b1;  // Assert ready for exactly 1 cycle

                if (|wstrb) begin
                    // Write operation
                    case (reg_word)
                        4'h0: data_out_reg <= apply_wstrb(data_out_reg, wdata, wstrb);
                        4'h2: dir_reg      <= apply_wstrb(dir_reg, wdata, wstrb);
                        4'h3: data_out_reg <= data_out_reg ^ apply_wstrb(32'h0000_0000, wdata, wstrb);
                        default: begin end
                    endcase
                end else begin
                    // Read operation — registered output
                    case (reg_word)
                        4'h0: rdata_reg <= data_out_reg;
                        4'h1: rdata_reg <= gpio_in;
                        4'h2: rdata_reg <= dir_reg;
                        default: rdata_reg <= 32'h0000_0000;
                    endcase
                end
            end
        end
    end
endmodule
