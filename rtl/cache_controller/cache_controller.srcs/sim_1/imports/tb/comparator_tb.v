`timescale 1ns / 1ps
`include "cache_config.vh"

module comparator_tb;
    reg  [`CACHE_TAG_BITS-1:0] input_a;
    reg  [`CACHE_TAG_BITS-1:0] input_b;
    wire tag_match;

    comparator dut (
        .input_a(input_a),
        .input_b(input_b),
        .tag_match(tag_match)
    );

    integer i;
    initial begin
        $dumpfile("sim_comparator.vcd");
        $dumpvars(0, comparator_tb);
        $display("--- Starting Comparator Coverage Test ---");
        // Test Match (Branch 1)
        input_a = 24'hABCDEF; input_b = 24'hABCDEF; #10;
        if (!tag_match) $display("ERR: Match failed");

        // Test Mismatch (Branch 2)
        input_a = 24'h111111; input_b = 24'h222222; #10;
        if (tag_match) $display("ERR: Mismatch failed");

        // Toggle coverage sweep
        for (i = 0; i < 20; i = i + 1) begin
            input_a = $random;
            input_b = input_a; #5;       // Force match
            input_b = ~$random; #5;      // Force mismatch
        end
        $display("--- Comparator Test Complete ---");
        $finish;
    end
endmodule