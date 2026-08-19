`timescale 1ns / 1ps
`include "cache_config.vh"

/*
 * cache_io_wrapper_sky130.v
 *
 * SKY130A pad wrapper for cache_top.
 *
 * IMPORTANT:
 *   - cache_top is unchanged.
 *   - Every cache_top single-direction signal is brought to a
 *     sky130_fd_io__top_gpiov2 pad.
 *   - No bidirectional cache signal exists in cache_top, so no I/O
 *     pad is configured as a bidirectional data bus.
 *   - Power/control settings below are fixed for a normal CMOS
 *     input/output configuration.
 *
 * The physical IO ring placement/abuttment and PG pad placement are
 * handled by the Fusion Compiler IO/floorplan stage.
 */

module cache_io_wrapper_sky130 (

    /* Physical signal pads */
    inout wire pad_clk,
    inout wire pad_reset,

    /* CPU request pads */
    inout wire                         pad_cpu_req_valid,
    inout wire [`CACHE_ADDR_WIDTH-1:0] pad_cachereq_addr,
    inout wire [`CACHE_DATA_WIDTH-1:0] pad_cachereq_data,
    inout wire [`CACHE_OPAQUE_WIDTH-1:0] pad_cachereq_opaque,
    inout wire [`CACHE_TYPE_WIDTH-1:0]   pad_cachereq_type,
    inout wire [`CACHE_LEN_WIDTH-1:0]    pad_cachereq_len,
    inout wire pad_cpu_req_ready,

    /* CPU response pads */
    inout wire                         pad_cpu_resp_valid,
    inout wire                         pad_cpu_resp_ready,
    inout wire [`CACHE_DATA_WIDTH-1:0] pad_cpu_resp_data,
    inout wire [`CACHE_OPAQUE_WIDTH-1:0] pad_cpu_resp_opaque,
    inout wire [`CACHE_LEN_WIDTH-1:0]    pad_cpu_resp_len,

    /* Memory request pads */
    inout wire                         pad_mem_req_valid,
    inout wire                         pad_mem_req_ready,
    inout wire                         pad_mem_req_write,
    inout wire [`CACHE_ADDR_WIDTH-1:0] pad_mem_req_addr,
    inout wire [`CACHE_LINE_BITS-1:0]  pad_mem_req_wdata,

    /* Memory response pads */
    inout wire                         pad_mem_resp_valid,
    inout wire [`CACHE_LINE_BITS-1:0]  pad_mem_resp_rdata,

    /* SKY130 power domains */
    inout wire VCCD,
    inout wire VSSD,
    inout wire VDDIO,
    inout wire VSSIO,
    inout wire VDDA,
    inout wire VSSA,
    inout wire VSWITCH,
    inout wire VCCHIB
);

    /*
     * The installed PDK contains the SKY130 IO blackbox definitions at:
     * /home/vlsi/Documents/PDK/sky130A/libs.ref/sky130_fd_io/verilog/
     *
     * Compile that file together with this wrapper. Do not include the
     * behavioral timing model in the FC synthesis netlist.
     */
    /*
     * SKY130 gpiov2 has VDDIO_Q and VSSIO_Q internal I/O supply rails.
     * For this digital-only wrapper, use the corresponding I/O rails.
     */
    wire VDDIO_Q;
    wire VSSIO_Q;

    assign VDDIO_Q = VDDIO;
    assign VSSIO_Q = VSSIO;

    /*
     * The gpiov2 cell exposes analog/ESD bus pins. They are not used by
     * this digital cache. Keep the local buses common to the wrapper.
     */
    wire AMUXBUS_A;
    wire AMUXBUS_B;

    /*
     * Fixed normal-operating controls.
     *
     * Input mode:
     *   DM      = 3'b001
     *   OE_N    = 1
     *
     * Output mode:
     *   DM      = 3'b110
     *   OE_N    = 0
     *
     * Other controls are held in the normal active digital mode.
     */
    localparam [2:0] IO_DM_INPUT  = 3'b001;
    localparam [2:0] IO_DM_OUTPUT = 3'b110;

    wire io_hld_h_n          = 1'b1;
    wire io_hld_ovr          = 1'b0;
    wire io_enable_h         = 1'b1;
    wire io_enable_inp_h     = 1'b1;
    wire io_enable_vdda_h    = 1'b1;
    wire io_enable_vswitch_h = 1'b1;
    wire io_enable_vddio     = 1'b1;
    wire io_inp_dis          = 1'b0;
    wire io_ib_mode_sel      = 1'b0;
    wire io_vtrip_sel        = 1'b0;
    wire io_slow             = 1'b0;
    wire io_analog_en        = 1'b0;
    wire io_analog_sel       = 1'b0;
    wire io_analog_pol       = 1'b0;

    /*
     * TIE outputs are not used by the cache wrapper.
     * The pad cells provide their own ESD tie outputs.
     */
    wire unused_tie_hi;
    wire unused_tie_lo;

    /* ================================================================
     * One reusable input-pad interface
     *
     * The actual pad signal is the wrapper's pad_* port.
     * IN is connected to the cache core.
     * OUT is disabled.
     * ================================================================ */

    /*
     * CLK
     */
    wire core_clk;
    sky130_fd_io__top_gpiov2 u_pad_clk (
        .IN_H(core_clk), .PAD(pad_clk),
        .PAD_A_NOESD_H(), .PAD_A_ESD_0_H(), .PAD_A_ESD_1_H(),
        .DM(IO_DM_INPUT), .HLD_H_N(io_hld_h_n), .INP_DIS(io_inp_dis),
        .IN(), .IB_MODE_SEL(io_ib_mode_sel),
        .ENABLE_H(io_enable_h), .ENABLE_VDDA_H(io_enable_vdda_h),
        .ENABLE_INP_H(io_enable_inp_h), .OE_N(1'b1),
        .TIE_HI_ESD(unused_tie_hi), .TIE_LO_ESD(unused_tie_lo),
        .SLOW(io_slow), .VTRIP_SEL(io_vtrip_sel), .HLD_OVR(io_hld_ovr),
        .ANALOG_EN(io_analog_en), .ANALOG_SEL(io_analog_sel),
        .ENABLE_VDDIO(io_enable_vddio),
        .ENABLE_VSWITCH_H(io_enable_vswitch_h),
        .ANALOG_POL(io_analog_pol), .OUT(1'b0),
        .AMUXBUS_A(AMUXBUS_A), .AMUXBUS_B(AMUXBUS_B),
        .VSSA(VSSA), .VDDA(VDDA), .VSWITCH(VSWITCH),
        .VDDIO_Q(VDDIO_Q), .VCCHIB(VCCHIB), .VDDIO(VDDIO),
        .VCCD(VCCD), .VSSIO(VSSIO), .VSSD(VSSD), .VSSIO_Q(VSSIO_Q)
    );

    wire core_reset;

    sky130_fd_io__top_gpiov2 u_pad_reset (
        .IN_H(core_reset), .PAD(pad_reset),
        .PAD_A_NOESD_H(), .PAD_A_ESD_0_H(), .PAD_A_ESD_1_H(),
        .DM(IO_DM_INPUT), .HLD_H_N(io_hld_h_n), .INP_DIS(io_inp_dis),
        .IN(), .IB_MODE_SEL(io_ib_mode_sel),
        .ENABLE_H(io_enable_h), .ENABLE_VDDA_H(io_enable_vdda_h),
        .ENABLE_INP_H(io_enable_inp_h), .OE_N(1'b1),
        .TIE_HI_ESD(), .TIE_LO_ESD(),
        .SLOW(io_slow), .VTRIP_SEL(io_vtrip_sel), .HLD_OVR(io_hld_ovr),
        .ANALOG_EN(io_analog_en), .ANALOG_SEL(io_analog_sel),
        .ENABLE_VDDIO(io_enable_vddio),
        .ENABLE_VSWITCH_H(io_enable_vswitch_h),
        .ANALOG_POL(io_analog_pol), .OUT(1'b0),
        .AMUXBUS_A(AMUXBUS_A), .AMUXBUS_B(AMUXBUS_B),
        .VSSA(VSSA), .VDDA(VDDA), .VSWITCH(VSWITCH),
        .VDDIO_Q(VDDIO_Q), .VCCHIB(VCCHIB), .VDDIO(VDDIO),
        .VCCD(VCCD), .VSSIO(VSSIO), .VSSD(VSSD), .VSSIO_Q(VSSIO_Q)
    );

    /*
     * Pad-cell generation macros.
     *
     * The macro creates a named SKY130 pad instance and exposes the
     * pad-side signal to the wrapper port.
     */
`define SKY130_INPUT_PAD(INSTANCE, PADNET, CORENET) \
    sky130_fd_io__top_gpiov2 INSTANCE ( \
        .IN_H(CORENET), .PAD(PADNET), \
        .PAD_A_NOESD_H(), .PAD_A_ESD_0_H(), .PAD_A_ESD_1_H(), \
        .DM(IO_DM_INPUT), .HLD_H_N(io_hld_h_n), .INP_DIS(io_inp_dis), \
        .IN(), .IB_MODE_SEL(io_ib_mode_sel), .ENABLE_H(io_enable_h), \
        .ENABLE_VDDA_H(io_enable_vdda_h), .ENABLE_INP_H(io_enable_inp_h), \
        .OE_N(1'b1), .TIE_HI_ESD(), .TIE_LO_ESD(), .SLOW(io_slow), \
        .VTRIP_SEL(io_vtrip_sel), .HLD_OVR(io_hld_ovr), \
        .ANALOG_EN(io_analog_en), .ANALOG_SEL(io_analog_sel), \
        .ENABLE_VDDIO(io_enable_vddio), \
        .ENABLE_VSWITCH_H(io_enable_vswitch_h), \
        .ANALOG_POL(io_analog_pol), .OUT(1'b0), \
        .AMUXBUS_A(AMUXBUS_A), .AMUXBUS_B(AMUXBUS_B), \
        .VSSA(VSSA), .VDDA(VDDA), .VSWITCH(VSWITCH), \
        .VDDIO_Q(VDDIO_Q), .VCCHIB(VCCHIB), .VDDIO(VDDIO), \
        .VCCD(VCCD), .VSSIO(VSSIO), .VSSD(VSSD), .VSSIO_Q(VSSIO_Q) \
    );

`define SKY130_OUTPUT_PAD(INSTANCE, PADNET, CORENET) \
    sky130_fd_io__top_gpiov2 INSTANCE ( \
        .IN_H(), .PAD(PADNET), \
        .PAD_A_NOESD_H(), .PAD_A_ESD_0_H(), .PAD_A_ESD_1_H(), \
        .DM(IO_DM_OUTPUT), .HLD_H_N(io_hld_h_n), .INP_DIS(1'b1), \
        .IN(), .IB_MODE_SEL(io_ib_mode_sel), .ENABLE_H(io_enable_h), \
        .ENABLE_VDDA_H(io_enable_vdda_h), .ENABLE_INP_H(io_enable_inp_h), \
        .OE_N(1'b0), .TIE_HI_ESD(), .TIE_LO_ESD(), .SLOW(io_slow), \
        .VTRIP_SEL(io_vtrip_sel), .HLD_OVR(io_hld_ovr), \
        .ANALOG_EN(io_analog_en), .ANALOG_SEL(io_analog_sel), \
        .ENABLE_VDDIO(io_enable_vddio), \
        .ENABLE_VSWITCH_H(io_enable_vswitch_h), \
        .ANALOG_POL(io_analog_pol), .OUT(CORENET), \
        .AMUXBUS_A(AMUXBUS_A), .AMUXBUS_B(AMUXBUS_B), \
        .VSSA(VSSA), .VDDA(VDDA), .VSWITCH(VSWITCH), \
        .VDDIO_Q(VDDIO_Q), .VCCHIB(VCCHIB), .VDDIO(VDDIO), \
        .VCCD(VCCD), .VSSIO(VSSIO), .VSSD(VSSD), .VSSIO_Q(VSSIO_Q) \
    );

    /* ================================================================
     * Core wires
     * ================================================================ */

    wire core_cpu_req_valid;
    wire core_cpu_req_ready;
    wire [`CACHE_ADDR_WIDTH-1:0] core_cachereq_addr;
    wire [`CACHE_DATA_WIDTH-1:0] core_cachereq_data;
    wire [`CACHE_OPAQUE_WIDTH-1:0] core_cachereq_opaque;
    wire [`CACHE_TYPE_WIDTH-1:0] core_cachereq_type;
    wire [`CACHE_LEN_WIDTH-1:0] core_cachereq_len;

    wire core_cpu_resp_valid;
    wire core_cpu_resp_ready;
    wire [`CACHE_DATA_WIDTH-1:0] core_cpu_resp_data;
    wire [`CACHE_OPAQUE_WIDTH-1:0] core_cpu_resp_opaque;
    wire [`CACHE_LEN_WIDTH-1:0] core_cpu_resp_len;

    wire core_mem_req_valid;
    wire core_mem_req_ready;
    wire core_mem_req_write;
    wire [`CACHE_ADDR_WIDTH-1:0] core_mem_req_addr;
    wire [`CACHE_LINE_BITS-1:0] core_mem_req_wdata;

    wire core_mem_resp_valid;
    wire [`CACHE_LINE_BITS-1:0] core_mem_resp_rdata;

    /* ================================================================
     * CPU request input pads
     * ================================================================ */

    `SKY130_INPUT_PAD(u_pad_cpu_req_valid, pad_cpu_req_valid, core_cpu_req_valid)

    genvar i;
    generate
        for (i = 0; i < `CACHE_ADDR_WIDTH; i = i + 1) begin : GEN_CPU_ADDR_IN
            `SKY130_INPUT_PAD(
                u_pad_cachereq_addr,
                pad_cachereq_addr[i],
                core_cachereq_addr[i]
            )
        end
    endgenerate

    generate
        for (i = 0; i < `CACHE_DATA_WIDTH; i = i + 1) begin : GEN_CPU_DATA_IN
            `SKY130_INPUT_PAD(
                u_pad_cachereq_data,
                pad_cachereq_data[i],
                core_cachereq_data[i]
            )
        end
    endgenerate

    generate
        for (i = 0; i < `CACHE_OPAQUE_WIDTH; i = i + 1) begin : GEN_CPU_OPAQUE_IN
            `SKY130_INPUT_PAD(
                u_pad_cachereq_opaque,
                pad_cachereq_opaque[i],
                core_cachereq_opaque[i]
            )
        end
    endgenerate

    generate
        for (i = 0; i < `CACHE_TYPE_WIDTH; i = i + 1) begin : GEN_CPU_TYPE_IN
            `SKY130_INPUT_PAD(
                u_pad_cachereq_type,
                pad_cachereq_type[i],
                core_cachereq_type[i]
            )
        end
    endgenerate

    generate
        for (i = 0; i < `CACHE_LEN_WIDTH; i = i + 1) begin : GEN_CPU_LEN_IN
            `SKY130_INPUT_PAD(
                u_pad_cachereq_len,
                pad_cachereq_len[i],
                core_cachereq_len[i]
            )
        end
    endgenerate

    /* CPU response ready is an input to the cache */
    `SKY130_INPUT_PAD(u_pad_cpu_resp_ready, pad_cpu_resp_ready, core_cpu_resp_ready)

    /* Memory request ready is an input to the cache */
    `SKY130_INPUT_PAD(u_pad_mem_req_ready, pad_mem_req_ready, core_mem_req_ready)

    /* Memory response inputs */
    `SKY130_INPUT_PAD(u_pad_mem_resp_valid, pad_mem_resp_valid, core_mem_resp_valid)

    generate
        for (i = 0; i < `CACHE_LINE_BITS; i = i + 1) begin : GEN_MEM_RDATA_IN
            `SKY130_INPUT_PAD(
                u_pad_mem_resp_rdata,
                pad_mem_resp_rdata[i],
                core_mem_resp_rdata[i]
            )
        end
    endgenerate

    /* ================================================================
     * CPU request ready output
     * ================================================================ */

    `SKY130_OUTPUT_PAD(u_pad_cpu_req_ready, pad_cpu_req_ready, core_cpu_req_ready)

    /* CPU response outputs */
    `SKY130_OUTPUT_PAD(u_pad_cpu_resp_valid, pad_cpu_resp_valid, core_cpu_resp_valid)

    generate
        for (i = 0; i < `CACHE_DATA_WIDTH; i = i + 1) begin : GEN_CPU_RESP_DATA_OUT
            `SKY130_OUTPUT_PAD(
                u_pad_cpu_resp_data,
                pad_cpu_resp_data[i],
                core_cpu_resp_data[i]
            )
        end
    endgenerate

    generate
        for (i = 0; i < `CACHE_OPAQUE_WIDTH; i = i + 1) begin : GEN_CPU_RESP_OPAQUE_OUT
            `SKY130_OUTPUT_PAD(
                u_pad_cpu_resp_opaque,
                pad_cpu_resp_opaque[i],
                core_cpu_resp_opaque[i]
            )
        end
    endgenerate

    generate
        for (i = 0; i < `CACHE_LEN_WIDTH; i = i + 1) begin : GEN_CPU_RESP_LEN_OUT
            `SKY130_OUTPUT_PAD(
                u_pad_cpu_resp_len,
                pad_cpu_resp_len[i],
                core_cpu_resp_len[i]
            )
        end
    endgenerate

    /* Memory request outputs */
    `SKY130_OUTPUT_PAD(u_pad_mem_req_valid, pad_mem_req_valid, core_mem_req_valid)
    `SKY130_OUTPUT_PAD(u_pad_mem_req_write, pad_mem_req_write, core_mem_req_write)

    generate
        for (i = 0; i < `CACHE_ADDR_WIDTH; i = i + 1) begin : GEN_MEM_ADDR_OUT
            `SKY130_OUTPUT_PAD(
                u_pad_mem_req_addr,
                pad_mem_req_addr[i],
                core_mem_req_addr[i]
            )
        end
    endgenerate

    generate
        for (i = 0; i < `CACHE_LINE_BITS; i = i + 1) begin : GEN_MEM_WDATA_OUT
            `SKY130_OUTPUT_PAD(
                u_pad_mem_req_wdata,
                pad_mem_req_wdata[i],
                core_mem_req_wdata[i]
            )
        end
    endgenerate

    /* ================================================================
     * cache_top instance
     * ================================================================ */

    cache_top u_cache_top (
        .clk              (core_clk),
        .reset            (core_reset),

        .cpu_req_valid    (core_cpu_req_valid),
        .cpu_req_ready    (core_cpu_req_ready),

        .cachereq_addr    (core_cachereq_addr),
        .cachereq_data    (core_cachereq_data),
        .cachereq_opaque  (core_cachereq_opaque),
        .cachereq_type    (core_cachereq_type),
        .cachereq_len     (core_cachereq_len),

        .cpu_resp_valid   (core_cpu_resp_valid),
        .cpu_resp_ready   (core_cpu_resp_ready),
        .cpu_resp_data    (core_cpu_resp_data),
        .cpu_resp_opaque  (core_cpu_resp_opaque),
        .cpu_resp_len     (core_cpu_resp_len),

        .mem_req_valid    (core_mem_req_valid),
        .mem_req_ready    (core_mem_req_ready),
        .mem_req_write    (core_mem_req_write),
        .mem_req_addr     (core_mem_req_addr),
        .mem_req_wdata    (core_mem_req_wdata),

        .mem_resp_valid   (core_mem_resp_valid),
        .mem_resp_rdata   (core_mem_resp_rdata)
    );

endmodule
