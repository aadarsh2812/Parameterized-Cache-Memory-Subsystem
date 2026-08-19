`timescale 1ns / 1ps
`include "cache_config.vh"
//==================================================================
// Module Name : cache_top
// Project     : Parameterized Cache Memory Subsystem
// Author      : AADARSH K.A.S
// Description : Top-level module for the direct-mapped L1 cache.
//               Connects the cache controller and datapath.
//==================================================================
module cache_top
(
    input clk,
    input reset,

    // CPU request interface
    input cpu_req_valid,
    output cpu_req_ready,

    input [`CACHE_ADDR_WIDTH-1:0]   cachereq_addr,
    input [`CACHE_DATA_WIDTH-1:0]   cachereq_data,
    input [`CACHE_OPAQUE_WIDTH-1:0] cachereq_opaque,
    input [`CACHE_TYPE_WIDTH-1:0]   cachereq_type,
    input [`CACHE_LEN_WIDTH-1:0]    cachereq_len,

    // CPU response interface
    output cpu_resp_valid,
    input cpu_resp_ready,

    output [`CACHE_DATA_WIDTH-1:0]   cpu_resp_data,
    output [`CACHE_OPAQUE_WIDTH-1:0] cpu_resp_opaque,
    output [`CACHE_LEN_WIDTH-1:0]    cpu_resp_len,

    // Memory request interface
    output mem_req_valid,
    input mem_req_ready,

    output mem_req_write,
    output [`CACHE_ADDR_WIDTH-1:0] mem_req_addr,
    output [`CACHE_LINE_BITS-1:0]  mem_req_wdata,

    // Memory response interface
    input mem_resp_valid,
    input [`CACHE_LINE_BITS-1:0] mem_resp_rdata
);


// Request register control

wire request_register_load;


// Array control signals

wire tag_array_ren;
wire tag_array_wen;

wire valid_array_ren;
wire valid_array_wen;

wire dirty_array_ren;
wire dirty_array_wen;

wire data_array_ren;
wire data_array_wen;


// Datapath control signals

wire write_hit_update;
wire refill_update;
wire evict_active;
wire init_update;


// Datapath status signals

wire [`CACHE_TYPE_WIDTH-1:0] cachereq_type_reg;

wire tag_match;
wire valid_array_rdata;
wire dirty_array_rdata;


// Cache controller

cache_controller u_cache_controller
(
    .clk                   (clk),
    .reset                 (reset),

    // CPU interface
    .cpu_req_valid         (cpu_req_valid),
    .cpu_req_ready         (cpu_req_ready),

    .cpu_resp_ready        (cpu_resp_ready),
    .cpu_resp_valid        (cpu_resp_valid),

    .cachereq_type_reg     (cachereq_type_reg),

    // Cache status
    .tag_match             (tag_match),
    .valid_array_rdata     (valid_array_rdata),
    .dirty_array_rdata     (dirty_array_rdata),

    // Memory interface
    .mem_req_ready         (mem_req_ready),
    .mem_resp_valid        (mem_resp_valid),

    .mem_req_valid         (mem_req_valid),
    .mem_req_write         (mem_req_write),

    // Request register
    .request_register_load (request_register_load),

    // Tag array
    .tag_array_ren         (tag_array_ren),
    .tag_array_wen         (tag_array_wen),

    // Valid array
    .valid_array_ren       (valid_array_ren),
    .valid_array_wen       (valid_array_wen),

    // Dirty array
    .dirty_array_ren       (dirty_array_ren),
    .dirty_array_wen       (dirty_array_wen),

    // Data array
    .data_array_ren        (data_array_ren),
    .data_array_wen        (data_array_wen),

    // Datapath control
    .write_hit_update      (write_hit_update),
    .refill_update         (refill_update),
    .evict_active          (evict_active),
    .init_update           (init_update)
);


// Cache datapath

cache_datapath u_cache_datapath
(
    .clk                   (clk),
    .reset                 (reset),

    // CPU request
    .cachereq_addr         (cachereq_addr),
    .cachereq_data         (cachereq_data),
    .cachereq_opaque       (cachereq_opaque),
    .cachereq_type         (cachereq_type),
    .cachereq_len          (cachereq_len),

    // Request register control
    .request_register_load (request_register_load),

    // Tag array control
    .tag_array_ren         (tag_array_ren),
    .tag_array_wen         (tag_array_wen),

    // Valid array control
    .valid_array_ren       (valid_array_ren),
    .valid_array_wen       (valid_array_wen),

    // Dirty array control
    .dirty_array_ren       (dirty_array_ren),
    .dirty_array_wen       (dirty_array_wen),

    // Data array control
    .data_array_ren        (data_array_ren),
    .data_array_wen        (data_array_wen),

    // Datapath control
    .write_hit_update      (write_hit_update),
    .refill_update         (refill_update),
    .evict_active          (evict_active),
    .init_update           (init_update),

    // Memory response
    .mem_resp_valid        (mem_resp_valid),
    .mem_resp_rdata        (mem_resp_rdata),

    // Status to controller
    .cachereq_type_reg     (cachereq_type_reg),

    .tag_match             (tag_match),
    .valid_array_rdata     (valid_array_rdata),
    .dirty_array_rdata     (dirty_array_rdata),

    // CPU response
    .cpu_resp_data         (cpu_resp_data),
    .cpu_resp_opaque       (cpu_resp_opaque),
    .cpu_resp_len          (cpu_resp_len),

    // Memory request
    .mem_req_addr          (mem_req_addr),
    .mem_req_wdata         (mem_req_wdata)
);


endmodule