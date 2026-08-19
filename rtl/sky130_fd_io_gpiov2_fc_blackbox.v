`timescale 1ns / 1ps

(* blackbox *)
module sky130_fd_io__top_gpiov2 (
    OUT,
    OE_N,
    HLD_H_N,
    ENABLE_H,
    ENABLE_INP_H,
    ENABLE_VDDA_H,
    ENABLE_VSWITCH_H,
    ENABLE_VDDIO,
    INP_DIS,
    IB_MODE_SEL,
    VTRIP_SEL,
    SLOW,
    HLD_OVR,
    ANALOG_EN,
    ANALOG_SEL,
    ANALOG_POL,
    DM,
    PAD,
    PAD_A_NOESD_H,
    PAD_A_ESD_0_H,
    PAD_A_ESD_1_H,
    AMUXBUS_A,
    AMUXBUS_B,
    IN,
    IN_H,
    TIE_HI_ESD,
    TIE_LO_ESD,
    VDDIO,
    VDDIO_Q,
    VDDA,
    VCCD,
    VSWITCH,
    VCCHIB,
    VSSA,
    VSSD,
    VSSIO_Q,
    VSSIO
);

input        OUT;
input        OE_N;
input        HLD_H_N;
input        ENABLE_H;
input        ENABLE_INP_H;
input        ENABLE_VDDA_H;
input        ENABLE_VSWITCH_H;
input        ENABLE_VDDIO;
input        INP_DIS;
input        IB_MODE_SEL;
input        VTRIP_SEL;
input        SLOW;
input        HLD_OVR;
input        ANALOG_EN;
input        ANALOG_SEL;
input        ANALOG_POL;
input  [2:0] DM;

inout        PAD;
inout        PAD_A_NOESD_H;
inout        PAD_A_ESD_0_H;
inout        PAD_A_ESD_1_H;
inout        AMUXBUS_A;
inout        AMUXBUS_B;

output       IN;
output       IN_H;
output       TIE_HI_ESD;
output       TIE_LO_ESD;

inout        VDDIO;
inout        VDDIO_Q;
inout        VDDA;
inout        VCCD;
inout        VSWITCH;
inout        VCCHIB;
inout        VSSA;
inout        VSSD;
inout        VSSIO_Q;
inout        VSSIO;

endmodule
