`timescale 1ns / 1ps
`include "cache_config.vh"

//============================================================
// Module Name : tag_array
// Project     : Parameterized Cache Memory Subsystem 
// Author      : AADARSH K.A.S
// Description : Stores cache tags for each cache line.
//============================================================

module tag_array 
 (
    //Clock & Control

    input clk,
    input reset,

    input tag_array_ren,
    input tag_array_wen,

    // Inputs

    input [`CACHE_INDEX_BITS-1:0] cachereq_index_dec,
    input [`CACHE_TAG_BITS-1:0]   tag_array_wdata,

    //Otuputs 

    output reg [`CACHE_TAG_BITS-1:0] tag_array_rdata
 );

    // Internal Memory 

    reg [`CACHE_TAG_BITS-1:0] tag_mem [0:`CACHE_NUM_LINES-1];

    // Sequential Logic

    always @(posedge clk)
    begin
        if (reset)
        begin
            tag_array_rdata <= {`CACHE_TAG_BITS{1'b0}};
        end
        else
        begin

            // Write Operation

            if (tag_array_wen)
                tag_mem[cachereq_index_dec] <= tag_array_wdata;

            // Read Operation

            if (tag_array_ren)
                tag_array_rdata <= tag_mem[cachereq_index_dec];

        end
    end

endmodule