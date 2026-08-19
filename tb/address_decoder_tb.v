`timescale 1ns / 1ps
`include "cache_config.vh"

module address_decoder_tb;
    reg  [`CACHE_ADDR_WIDTH-1:0] cachereq_addr_reg;
    wire [`CACHE_TAG_BITS-1:0]   cachereq_tag_dec;
    wire [`CACHE_INDEX_BITS-1:0] cachereq_index_dec;
    wire [`CACHE_OFFSET_BITS-1:0] cachereq_offset_dec;

    address_decoder dut (
        .cachereq_addr_reg(cachereq_addr_reg),
        .cachereq_tag_dec(cachereq_tag_dec),
        .cachereq_index_dec(cachereq_index_dec),
        .cachereq_offset_dec(cachereq_offset_dec)
    );

    integer i;
    initial begin
        $dumpfile("sim_address_decoder.fsdb");
        $dumpvars(0, address_decoder_tb);
        $display("--- Starting Address Decoder Coverage Test ---");
        // Directed corner cases
        cachereq_addr_reg = 32'h0000_0000; #10;
        cachereq_addr_reg = 32'hFFFF_FFFF; #10;
        cachereq_addr_reg = 32'hAAAA_AAAA; #10;
        cachereq_addr_reg = 32'h5555_5555; #10;
        
        // Random sweep for 100% toggle coverage
        for (i = 0; i < 50; i = i + 1) begin
            cachereq_addr_reg = $random;
            #10;
        end
        $display("--- Address Decoder Test Complete ---");
        $finish;
    end
endmodule