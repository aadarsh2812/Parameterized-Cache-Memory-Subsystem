`timescale 1ns / 1ps
`include "cache_config.vh"

//============================================================
// Module Name : data_array
// Project     : Parameterized Cache Memory Subsystem
// Author      : AADARSH K.A.S
// Description : Stores cache line data and provides
//               controller-driven read/write access.
//============================================================

module data_array
(
    // Clock & Control

    input clk,
    input reset,

    input data_array_ren,
    input data_array_wen,

    // Inputs

    input [`CACHE_INDEX_BITS-1:0] cachereq_index_dec,
    input [`CACHE_LINE_BITS-1:0]  data_array_wdata,

    // Outputs

    output reg [`CACHE_LINE_BITS-1:0] data_array_rdata
);

    // Internal Memory

    integer i;

    reg [`CACHE_LINE_BITS-1:0] cache_data_mem [0:`CACHE_NUM_LINES-1];

    // Sequential Logic

    always @(posedge clk)
    begin
        if (reset)
        begin
            data_array_rdata <= {`CACHE_LINE_BITS{1'b0}};

            for (i = 0; i < `CACHE_NUM_LINES; i = i + 1)
            begin
                cache_data_mem[i] <= {`CACHE_LINE_BITS{1'b0}};
            end
        end
        else
        begin
            // Write Operation

            if (data_array_wen)
            begin
                cache_data_mem[cachereq_index_dec] <= data_array_wdata;
            end

            // Read Operation

            if (data_array_ren)
            begin
                data_array_rdata <= cache_data_mem[cachereq_index_dec];
            end
        end
    end

endmodule