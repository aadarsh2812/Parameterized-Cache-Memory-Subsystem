`timescale 1ns / 1ps
`include "cache_config.vh"

module tag_array_tb;
    reg clk;
    reg reset;
    reg tag_array_ren;
    reg tag_array_wen;
    reg [`CACHE_INDEX_BITS-1:0] cachereq_index_dec;
    reg [`CACHE_TAG_BITS-1:0] tag_array_wdata;
    
    wire [`CACHE_TAG_BITS-1:0] tag_array_rdata;

    tag_array dut (
        .clk(clk),
        .reset(reset),
        .tag_array_ren(tag_array_ren),
        .tag_array_wen(tag_array_wen),
        .cachereq_index_dec(cachereq_index_dec),
        .tag_array_wdata(tag_array_wdata),
        .tag_array_rdata(tag_array_rdata)
    );

    always #5 clk = ~clk;

    integer i;
    initial begin
        $dumpfile("sim_cache_datapath.fsdb");
        $dumpvars(0, tag_array_tb);
        clk = 0; reset = 1; 
        tag_array_ren = 0; tag_array_wen = 0; 
        cachereq_index_dec = 0; tag_array_wdata = 0;
        
        #20; 
        @(negedge clk) reset = 0;

        $display("--- Starting Tag Array Coverage Test ---");
        
        // Write Phase - Populate entire cache index space
        for (i = 0; i < `CACHE_NUM_LINES; i = i + 1) begin
            @(negedge clk);
            tag_array_wen = 1; 
            tag_array_ren = 0;
            cachereq_index_dec = i;
            // Mask random data to fit the exact tag bit-width
            tag_array_wdata = $random & ((1<<`CACHE_TAG_BITS)-1); 
        end

        // Read Phase - Verify outputs on the bus
        for (i = 0; i < `CACHE_NUM_LINES; i = i + 1) begin
            @(negedge clk);
            tag_array_wen = 0; 
            tag_array_ren = 1;
            cachereq_index_dec = i;
        end

        // Idle Phase 
        @(negedge clk);
        tag_array_ren = 0;
        
        #20 $display("--- Tag Array Test Complete ---");
        $finish;
    end
endmodule