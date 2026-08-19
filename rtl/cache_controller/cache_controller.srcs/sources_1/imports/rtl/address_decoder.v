`timescale 1ns / 1ps
`include "cache_config.vh"

//============================================================
// Module Name : address_decoder
// Project     : Parameterized Cache Memory Subsystem
// Author      : AADARSH K.A.S
// Description : Decodes the registered cache request address
//               into Tag, Index and Offset fields.
//============================================================

module address_decoder
(
    // Inputs

    input [`CACHE_ADDR_WIDTH-1:0] cachereq_addr_reg,

    // Outputs

    output [`CACHE_TAG_BITS-1:0]    cachereq_tag_dec,
    output [`CACHE_INDEX_BITS-1:0]  cachereq_index_dec,
    output [`CACHE_OFFSET_BITS-1:0] cachereq_offset_dec
);

// Combinational Logic

// Byte Offset

assign cachereq_offset_dec =
       cachereq_addr_reg[`CACHE_OFFSET_BITS-1:0];

// Cache Index

assign cachereq_index_dec =
       cachereq_addr_reg[`CACHE_OFFSET_BITS + `CACHE_INDEX_BITS - 1 : `CACHE_OFFSET_BITS];

// Cache Tag

assign cachereq_tag_dec =
       cachereq_addr_reg[`CACHE_ADDR_WIDTH-1 :
                         `CACHE_OFFSET_BITS + `CACHE_INDEX_BITS];

endmodule
