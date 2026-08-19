`timescale 1ns / 1ps
`include "cache_config.vh"

module request_register_tb;
    reg clk, reset, load;
    reg [`CACHE_ADDR_WIDTH-1:0]   cachereq_addr;
    reg [`CACHE_DATA_WIDTH-1:0]   cachereq_data;
    reg [`CACHE_OPAQUE_WIDTH-1:0] cachereq_opaque;
    reg [`CACHE_TYPE_WIDTH-1:0]   cachereq_type;
    reg [`CACHE_LEN_WIDTH-1:0]    cachereq_len;

    wire [`CACHE_ADDR_WIDTH-1:0]   cachereq_addr_reg;
    wire [`CACHE_DATA_WIDTH-1:0]   cachereq_data_reg;
    wire [`CACHE_OPAQUE_WIDTH-1:0] cachereq_opaque_reg;
    wire [`CACHE_TYPE_WIDTH-1:0]   cachereq_type_reg;
    wire [`CACHE_LEN_WIDTH-1:0]    cachereq_len_reg;

    request_register dut (.*);
    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim_request_register.fsdb");
        $dumpvars(0, request_register_tb);
        clk = 0; reset = 1; load = 0;
        cachereq_addr = 0; cachereq_data = 0; cachereq_opaque = 0; 
        cachereq_type = 0; cachereq_len = 0;
        #15; @(negedge clk) reset = 0;

        // Coverage: load = 1
        @(negedge clk);
        load = 1;
        cachereq_addr = 32'hDEADBEEF; cachereq_data = 32'h12345678;
        cachereq_type = 2'b01; cachereq_len = 2'b10; cachereq_opaque = 8'hAA;
        
        // Coverage: load = 0 (Data should hold)
        @(negedge clk);
        load = 0;
        cachereq_addr = 32'h00000000; // Output should remain DEADBEEF
        
        #20 $finish;
    end
endmodule