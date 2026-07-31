`timescale 1ns/1ps
`include "cache_config.vh"

//============================================================
// Module Name : comparator
// Project     : Parameterized Cache Memory Subsystem
// Author      : AADARSH K.A.S
// Description : Compares the decoded request tag with the
//               tag read from the tag array.
//============================================================

module comparator
(
    input  [`CACHE_TAG_BITS-1:0] input_a,
    input  [`CACHE_TAG_BITS-1:0] input_b,

    output tag_match
);

assign tag_match = (input_a == input_b);

endmodule