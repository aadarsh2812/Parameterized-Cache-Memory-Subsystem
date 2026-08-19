`timescale 1ns / 1ps
`include "cache_config.vh"

//============================================================
// Module Name : dirty_array
// Project     : Parameterized Cache Memory Subsystem
// Author      : AADARSH K.A.S
// Description : Stores the Dirty bit for each cache line.
//============================================================

module dirty_array
(
    //Clock & Control
    input clk,
    input reset,

    input dirty_array_ren,
    input dirty_array_wen,

    // Input
    input [`CACHE_INDEX_BITS-1:0] cachereq_index_dec,
    input dirty_array_wdata,

    // Output
    output reg dirty_array_rdata
);
    integer i;
    reg dirty_mem [0:`CACHE_NUM_LINES-1];

    // Sequential Logic 

    always @(posedge clk)
    begin
        if (reset)
        begin
            dirty_array_rdata <= 1'b0; 
            for ( i=0; i<`CACHE_NUM_LINES; i = i+1 )
            begin 
                dirty_mem[i] <=1'b0;
            end
        end
        else
        begin
            if (dirty_array_wen)
            // Write Operartion 
            begin
                dirty_mem[cachereq_index_dec] <= dirty_array_wdata; 
            end 
            if(dirty_array_ren )
            //Read Operation
            begin
                dirty_array_rdata <= dirty_mem[cachereq_index_dec];
            end 
        end 
    end 
endmodule 