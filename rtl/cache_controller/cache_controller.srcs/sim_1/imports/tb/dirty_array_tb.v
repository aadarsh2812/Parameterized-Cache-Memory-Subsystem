`timescale 1ns / 1ps
`include "cache_config.vh"

module data_array_tb;
    reg clk, reset, data_array_ren, data_array_wen;
    reg  [`CACHE_INDEX_BITS-1:0] cachereq_index_dec;
    reg  [`CACHE_LINE_BITS-1:0] data_array_wdata;
    wire [`CACHE_LINE_BITS-1:0] data_array_rdata;
data_array dut (
    .clk                (clk),
    .reset              (reset),
    .data_array_ren     (data_array_ren),
    .data_array_wen     (data_array_wen),
    .cachereq_index_dec (cachereq_index_dec),
    .data_array_wdata   (data_array_wdata),
    .data_array_rdata   (data_array_rdata)
);
    always #5 clk = ~clk;

    integer i;
    initial begin
        $dumpfile("sim_dirty_array.vcd");
        $dumpvars(0, data_array_tb);
        clk = 0; reset = 1; data_array_ren = 0; data_array_wen = 0; 
        cachereq_index_dec = 0; data_array_wdata = 0;
        #20; @(negedge clk) reset = 0;

        $display("--- Starting Data Array Coverage Test ---");
        // Write sweeps
        for (i = 0; i < 4; i = i + 1) begin
            @(negedge clk);
            data_array_wen = 1; data_array_ren = 0;
            cachereq_index_dec = i;
            // Generate a wide random payload
            data_array_wdata = {$random, $random, $random, $random};
        end

        // Read sweeps
        for (i = 0; i < 4; i = i + 1) begin
            @(negedge clk);
            data_array_wen = 0; data_array_ren = 1;
            cachereq_index_dec = i;
        end

        #20 $display("--- Data Array Test Complete ---");
        $finish;
    end
endmodule