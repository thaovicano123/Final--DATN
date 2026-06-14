`timescale 1ns/1ps

module tb_picorv32;
    reg clk;
    reg resetn;
    reg mem_ready;
    reg [31:0] mem_rdata;
    reg [31:0] irq;

    wire mem_valid;
    wire mem_instr;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wstrb;

    integer cycles;
    integer mem_index;
    integer instr_fetch_count;
    integer addr_change_count;
    reg [31:0] last_addr;

    // Simple instruction/data memory model
    reg [31:0] memory [0:1023];
    
    picorv32 #(
        .PROGADDR_RESET(32'h0000_0000),
        .PROGADDR_IRQ  (32'h0000_0010),
        .ENABLE_IRQ    (1),
        .ENABLE_IRQ_QREGS(1)
    ) u_cpu (
        .clk(clk),
        .resetn(resetn),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .irq(irq)
    );
    
    initial begin
        for (mem_index = 0; mem_index < 1024; mem_index = mem_index + 1) begin
            memory[mem_index] = 32'h00000013; // NOP
        end

        // Small program that continuously fetches sequential addresses.
        memory[0] = 32'h00000093; // addi x1, x0, 0
        memory[1] = 32'h00108093; // addi x1, x1, 1
        memory[2] = 32'h00208113; // addi x2, x1, 2
        memory[3] = 32'h00310193; // addi x3, x2, 3
        memory[4] = 32'h00000013; // nop
        memory[5] = 32'h00000013; // nop
    end

    always @(*) begin
        mem_ready = mem_valid;
        mem_rdata = memory[mem_addr[31:2]];
    end

    always @(posedge clk) begin
        if (mem_valid && !mem_instr && |mem_wstrb) begin
            if (mem_wstrb[0]) memory[mem_addr[31:2]][7:0] <= mem_wdata[7:0];
            if (mem_wstrb[1]) memory[mem_addr[31:2]][15:8] <= mem_wdata[15:8];
            if (mem_wstrb[2]) memory[mem_addr[31:2]][23:16] <= mem_wdata[23:16];
            if (mem_wstrb[3]) memory[mem_addr[31:2]][31:24] <= mem_wdata[31:24];
        end
    end

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        mem_ready = 1'b0;
        mem_rdata = 32'h00000000;
        irq = 32'h00000000;

        cycles = 0;
        instr_fetch_count = 0;
        addr_change_count = 0;
        last_addr = 32'hFFFF_FFFF;

        $dumpfile("results/phase3/tb_picorv32.vcd");
        $dumpvars(0, tb_picorv32);

        repeat (10) @(posedge clk);
        resetn = 1'b1;
        repeat (200) begin
            @(posedge clk);
            if (mem_valid && mem_instr) begin
                instr_fetch_count = instr_fetch_count + 1;
                if (last_addr != mem_addr)
                    addr_change_count = addr_change_count + 1;
                last_addr = mem_addr;
            end
        end

        if (instr_fetch_count < 10) begin
            $display("[FAIL] Too few instruction fetches: %0d", instr_fetch_count);
            $fatal(1);
        end

        if (addr_change_count < 4) begin
            $display("[FAIL] PC/address did not advance as expected: %0d changes", addr_change_count);
            $fatal(1);
        end

        $display("[PASS] Instruction fetch count: %0d", instr_fetch_count);
        $display("[PASS] Instruction address changes: %0d", addr_change_count);
        $display("PicoRV32 TEST: ALL TESTS PASSED");
        $finish;
    end

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (resetn) cycles = cycles + 1;
    end
endmodule