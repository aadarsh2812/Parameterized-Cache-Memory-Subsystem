`timescale 1ns / 1ps
`include "cache_config.vh"

//============================================================
// Module Name : valid_array
// Project     : Parameterized Cache Memory Subsystem
// Author      : AADARSH K.A.S
// Description : Stores the valid bit for each cache line.
//============================================================

module valid_array
(
    //Clock & Control
    input clk,
    input reset,

    input valid_array_ren,
    input valid_array_wen,

    // Input
    input [`CACHE_INDEX_BITS-1:0] cachereq_index_dec,
    input valid_array_wdata,

    //
    output reg valid_array_rdata
);
    integer i;
    reg valid_mem [0:`CACHE_NUM_LINES-1];

    // Sequentiall Logic 

    always @(posedge clk)
    begin
        if (reset)
        begin
            valid_array_rdata <= 1'b0; 
            for ( i=0; i<`CACHE_NUM_LINES; i = i+1 )
            begin 
                valid_mem[i] <=1'b0;
            end
        end
        else
        begin
            if (valid_array_wen)
            //Write Operartion 
            begin
                valid_mem[cachereq_index_dec] <= valid_array_wdata; 
            end 
            if(valid_array_ren )
            //Read Operation
            begin
                valid_array_rdata <= valid_mem[cachereq_index_dec];
            end 
        end 
    end 
endmodule 