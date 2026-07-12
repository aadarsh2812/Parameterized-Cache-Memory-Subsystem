`timescale 1ns / 1ps

//============================================================
// File Name   : mux.v
// Project     : Parameterized Cache Memory Subsystem
// Author      : AADARSH K.A.S
// Description : Generic parameterized 2:1 and 3:1 multiplexers.
//============================================================


//============================================================
// Module Name : mux2
// Description : Generic parameterized 2-to-1 multiplexer.
//============================================================

module mux2
#(
    parameter WIDTH = 32
)
(
    // Inputs

    input [WIDTH-1:0] din0,
    input [WIDTH-1:0] din1,
    input             sel,

    // Outputs

    output [WIDTH-1:0] out
);

// Combinational Logic

assign out = (sel) ? din1 : din0;

endmodule


//============================================================
// Module Name : mux3
// Description : Generic parameterized 3-to-1 multiplexer.
//============================================================

module mux3
#(
    parameter WIDTH = 32
)

    //Input
    
    input [WIDTH-1:0] din0;
    input [WIDTH-1:0] din1;
    input [WIDTH-1:0] din2;

    input [1:0] sel;

    //output

    output [WIDTH-1:0] dout
;

assign dout = (sel == 2'b00) ? din0:
              (sel == 2'b01) ? din1:
              (sel == 2'b10) ? din2:
                            {WIDTH{1'b0}};

endmodule 

