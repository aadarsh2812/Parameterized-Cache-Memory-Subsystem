`timescale 1ns / 1ps
`include "cache_config.vh"

module data_array_tb;
    
    // Clock & Control
    reg clk;
    reg reset;
    reg data_array_ren;
    reg data_array_wen;

    // Inputs
    reg  [`CACHE_INDEX_BITS-1:0] cachereq_index_dec;
    reg  [`CACHE_LINE_BITS-1:0]  data_array_wdata;

    // Outputs
    wire [`CACHE_LINE_BITS-1:0] data_array_rdata;

    // Instantiate DUT
    data_array dut (
        .clk(clk),
        .reset(reset),
        .data_array_ren(data_array_ren),
        .data_array_wen(data_array_wen),
        .cachereq_index_dec(cachereq_index_dec),
        .data_array_wdata(data_array_wdata),
        .data_array_rdata(data_array_rdata)
    );

    // Clock generation
    always #5 clk = ~clk;

    integer i;

    initial begin
        $dumpfile("sim_data_array.vcd");
        $dumpvars(0, data_array_tb);
        // 1. Initialization
        clk = 0; 
        reset = 1;
        data_array_ren = 0; 
        data_array_wen = 0;
        cachereq_index_dec = 0; 
        data_array_wdata = 0;

        // 2. Hold reset, then release on falling edge to align perfectly
        #20;
        @(negedge clk) reset = 0;

        $display("--- Starting Data Array Coverage Test ---");

        // 3. Write Phase - Sweep through ALL cache lines
        // This ensures the entire memory block is initialized and branch logic is exercised
        for (i = 0; i < `CACHE_NUM_LINES; i = i + 1) begin
            @(negedge clk);
            data_array_wen = 1;
            data_array_ren = 0;
            cachereq_index_dec = i;
            
            // Generate a wide random payload for the cache line
            // Concatenating multiple 32-bit $random calls to fill the cache line width
            data_array_wdata = {$random, $random, $random, $random}; 
        end

        // 4. Read Phase - Sweep through ALL cache lines again
        // Verifies the ren (read enable) logic and reads back the written data
        for (i = 0; i < `CACHE_NUM_LINES; i = i + 1) begin
            @(negedge clk);
            data_array_wen = 0;
            data_array_ren = 1;
            cachereq_index_dec = i;
        end

        // 5. Idle Phase - Check coverage when neither reading nor writing
        @(negedge clk);
        data_array_ren = 0;
        data_array_wen = 0;

        #30 $display("--- Data Array Test Complete ---");
        $finish;
    end

endmodule