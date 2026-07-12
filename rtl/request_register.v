`timescale 1ns / 1ps
`include "cache_config.vh"

//============================================================
// Module Name : request_register
// Project     : Parameterized Cache Memory Subsystem
// Author      : AADARSH K.A.S
// Description : Stores the incoming CPU cache request.
//============================================================

module request_register
(
    // Clock & Control

    input clk,
    input reset,
    input load,

    // Cache Request Inputs

    input [`CACHE_ADDR_WIDTH-1:0]      cachereq_addr,
    input [`CACHE_DATA_WIDTH-1:0]      cachereq_data,
    input [`CACHE_OPAQUE_WIDTH-1:0]    cachereq_opaque,
    input [`CACHE_TYPE_WIDTH-1:0]      cachereq_type,
    input [`CACHE_LEN_WIDTH-1:0]       cachereq_len,

    // Registered Outputs

    output reg [`CACHE_ADDR_WIDTH-1:0]      cachereq_addr_reg,
    output reg [`CACHE_DATA_WIDTH-1:0]      cachereq_data_reg,
    output reg [`CACHE_OPAQUE_WIDTH-1:0]    cachereq_opaque_reg,
    output reg [`CACHE_TYPE_WIDTH-1:0]      cachereq_type_reg,
    output reg [`CACHE_LEN_WIDTH-1:0]       cachereq_len_reg
);

// Sequential Logic

always @(posedge clk)
begin
    if (reset)
    begin
        cachereq_addr_reg   <= {`CACHE_ADDR_WIDTH{1'b0}};
        cachereq_data_reg   <= {`CACHE_DATA_WIDTH{1'b0}};
        cachereq_opaque_reg <= {`CACHE_OPAQUE_WIDTH{1'b0}};
        cachereq_type_reg   <= {`CACHE_TYPE_WIDTH{1'b0}};
        cachereq_len_reg    <= {`CACHE_LEN_WIDTH{1'b0}};
    end
    else if (load)
    begin
        cachereq_addr_reg   <= cachereq_addr;
        cachereq_data_reg   <= cachereq_data;
        cachereq_opaque_reg <= cachereq_opaque;
        cachereq_type_reg   <= cachereq_type;
        cachereq_len_reg    <= cachereq_len;
    end
end

endmodule