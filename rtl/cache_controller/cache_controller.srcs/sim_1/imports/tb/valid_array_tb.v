`timescale 1ns / 1ps
`include "cache_config.vh"

module valid_array_tb;
    reg clk;
    reg reset;
    reg valid_array_ren;
    reg valid_array_wen;
    reg [`CACHE_INDEX_BITS-1:0] cachereq_index_dec;
    reg valid_array_wdata;
    
    wire valid_array_rdata;

valid_array dut (
    .clk                (clk),
    .reset              (reset),
    .valid_array_ren    (valid_array_ren),
    .valid_array_wen    (valid_array_wen),
    .cachereq_index_dec (cachereq_index_dec),
    .valid_array_wdata  (valid_array_wdata),
    .valid_array_rdata  (valid_array_rdata)
);
    always #5 clk = ~clk;

    integer i;
    initial begin
        $dumpfile("sim_valid_array.vcd");
        $dumpvars(0, valid_array_tb);
        clk = 0; reset = 1; 
        valid_array_ren = 0; valid_array_wen = 0; 
        cachereq_index_dec = 0; valid_array_wdata = 0;
        
        // Hold reset to cover loop initialization
        #20; 
        @(negedge clk) reset = 0;

        $display("--- Starting Valid Array Coverage Test ---");
        
        // Write Phase - Cover all indices to ensure full memory traversal
        for (i = 0; i < `CACHE_NUM_LINES; i = i + 1) begin
            @(negedge clk);
            valid_array_wen = 1;
            valid_array_ren = 0;
            cachereq_index_dec = i;
            valid_array_wdata = i % 2; // Alternating 1/0
        end

        // Read Phase - Verify all indices
        for (i = 0; i < `CACHE_NUM_LINES; i = i + 1) begin
            @(negedge clk);
            valid_array_wen = 0;
            valid_array_ren = 1;
            cachereq_index_dec = i;
        end

        // Idle Phase (Coverage for neither read nor write)
        @(negedge clk);
        valid_array_ren = 0;
        valid_array_wen = 0;
        
        #20 $display("--- Valid Array Test Complete ---");
        $finish;
    end
endmodule