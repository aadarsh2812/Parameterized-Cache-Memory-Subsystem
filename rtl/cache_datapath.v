`timescale 1ns / 1ps
`include "cache_config.vh"
//==========================================================
// Module Name : cache_datapath
// Project     : Parameterized Cache Memory Subsystem
// Author      : AADARSH K.A.S
// Description : Handles request storage, address decoding,
//               cache arrays, data selection, refill and
//               write-back datapaths.
//==========================================================
module cache_datapath
(
    input clk,
    input reset,

    // CPU request
    input [`CACHE_ADDR_WIDTH-1:0]   cachereq_addr,
    input [`CACHE_DATA_WIDTH-1:0]   cachereq_data,
    input [`CACHE_OPAQUE_WIDTH-1:0] cachereq_opaque,
    input [`CACHE_TYPE_WIDTH-1:0]   cachereq_type,
    input [`CACHE_LEN_WIDTH-1:0]    cachereq_len,

    // Request register control
    input request_register_load,

    // Array control
    input tag_array_ren,
    input tag_array_wen,

    input valid_array_ren,
    input valid_array_wen,

    input dirty_array_ren,
    input dirty_array_wen,

    input data_array_ren,
    input data_array_wen,

    // Datapath control
    input write_hit_update,
    input refill_update,
    input evict_active,
    input init_update,

    // Memory response
    input mem_resp_valid,
    input [`CACHE_LINE_BITS-1:0] mem_resp_rdata,

    // Status to controller
    output [`CACHE_TYPE_WIDTH-1:0] cachereq_type_reg,

    output tag_match,
    output valid_array_rdata,
    output dirty_array_rdata,

    // CPU response
    output [`CACHE_DATA_WIDTH-1:0]   cpu_resp_data,
    output [`CACHE_OPAQUE_WIDTH-1:0] cpu_resp_opaque,
    output [`CACHE_LEN_WIDTH-1:0]    cpu_resp_len,

    // Memory request
    output [`CACHE_ADDR_WIDTH-1:0] mem_req_addr,
    output [`CACHE_LINE_BITS-1:0]  mem_req_wdata
);


// Word organization

localparam WORD_BYTES =
    (`CACHE_DATA_WIDTH / `CACHE_BYTE_WIDTH);

localparam WORDS_PER_LINE =
    (`CACHE_LINE_BITS / `CACHE_DATA_WIDTH);

localparam WORD_SEL_BITS =
    $clog2(WORDS_PER_LINE);


// Registered request

wire [`CACHE_ADDR_WIDTH-1:0]   cachereq_addr_reg;
wire [`CACHE_DATA_WIDTH-1:0]   cachereq_data_reg;
wire [`CACHE_OPAQUE_WIDTH-1:0] cachereq_opaque_reg;
wire [`CACHE_LEN_WIDTH-1:0]    cachereq_len_reg;


// Decoded address

wire [`CACHE_TAG_BITS-1:0]    cachereq_tag_dec;
wire [`CACHE_INDEX_BITS-1:0]  cachereq_index_dec;
wire [`CACHE_OFFSET_BITS-1:0] cachereq_offset_dec;


// Array data

wire [`CACHE_TAG_BITS-1:0] tag_array_rdata;
wire [`CACHE_TAG_BITS-1:0] tag_array_wdata;

wire valid_array_wdata;
wire dirty_array_wdata;

wire [`CACHE_LINE_BITS-1:0] data_array_rdata;
reg  [`CACHE_LINE_BITS-1:0] data_array_wdata;


// Refill storage

reg [`CACHE_LINE_BITS-1:0] refill_data_reg;


// Word selection

wire [WORD_SEL_BITS-1:0] word_select;


// Store incoming CPU request

request_register u_request_register
(
    .clk                 (clk),
    .reset               (reset),
    .load                (request_register_load),

    .cachereq_addr       (cachereq_addr),
    .cachereq_data       (cachereq_data),
    .cachereq_opaque     (cachereq_opaque),
    .cachereq_type       (cachereq_type),
    .cachereq_len        (cachereq_len),

    .cachereq_addr_reg   (cachereq_addr_reg),
    .cachereq_data_reg   (cachereq_data_reg),
    .cachereq_opaque_reg (cachereq_opaque_reg),
    .cachereq_type_reg   (cachereq_type_reg),
    .cachereq_len_reg    (cachereq_len_reg)
);


// Decode request address

address_decoder u_address_decoder
(
    .cachereq_addr_reg   (cachereq_addr_reg),

    .cachereq_tag_dec    (cachereq_tag_dec),
    .cachereq_index_dec  (cachereq_index_dec),
    .cachereq_offset_dec (cachereq_offset_dec)
);


// Tag storage

tag_array u_tag_array
(
    .clk                (clk),
    .reset              (reset),

    .tag_array_ren      (tag_array_ren),
    .tag_array_wen      (tag_array_wen),

    .cachereq_index_dec (cachereq_index_dec),

    .tag_array_wdata    (tag_array_wdata),
    .tag_array_rdata    (tag_array_rdata)
);


// Valid-bit storage

valid_array u_valid_array
(
    .clk                (clk),
    .reset              (reset),

    .valid_array_ren    (valid_array_ren),
    .valid_array_wen    (valid_array_wen),

    .cachereq_index_dec (cachereq_index_dec),

    .valid_array_wdata  (valid_array_wdata),
    .valid_array_rdata  (valid_array_rdata)
);


// Dirty-bit storage

dirty_array u_dirty_array
(
    .clk                (clk),
    .reset              (reset),

    .dirty_array_ren    (dirty_array_ren),
    .dirty_array_wen    (dirty_array_wen),

    .cachereq_index_dec (cachereq_index_dec),

    .dirty_array_wdata  (dirty_array_wdata),
    .dirty_array_rdata  (dirty_array_rdata)
);


// Cache-line data storage

data_array u_data_array
(
    .clk                (clk),
    .reset              (reset),

    .data_array_ren     (data_array_ren),
    .data_array_wen     (data_array_wen),

    .cachereq_index_dec (cachereq_index_dec),

    .data_array_wdata   (data_array_wdata),
    .data_array_rdata   (data_array_rdata)
);


// Compare requested and stored tags

assign tag_match =
       (cachereq_tag_dec == tag_array_rdata);


// Select the requested word inside the cache line

assign word_select =
       cachereq_offset_dec[
           `CACHE_OFFSET_BITS-1 :
           $clog2(WORD_BYTES)
       ];


// Return selected word to CPU

assign cpu_resp_data =
       data_array_rdata[
           (word_select * `CACHE_DATA_WIDTH)
           +: `CACHE_DATA_WIDTH
       ];


// Return request metadata with the response

assign cpu_resp_opaque = cachereq_opaque_reg;
assign cpu_resp_len    = cachereq_len_reg;


// Capture line returned by lower memory

always @(posedge clk)
begin

    if (reset)
    begin
        refill_data_reg <= {`CACHE_LINE_BITS{1'b0}};
    end

    else if (mem_resp_valid && !evict_active)
    begin
        refill_data_reg <= mem_resp_rdata;
    end

end


// New lines use the requested tag

assign tag_array_wdata =
       cachereq_tag_dec;


// Refill and initialization create valid lines

assign valid_array_wdata =
       1'b1;


// Write hits create dirty lines.
// Refill and initialization create clean lines.

assign dirty_array_wdata =
       write_hit_update ? 1'b1 :
                          1'b0;


// Select data written into the data array

always @(*)
begin

    data_array_wdata =
        {`CACHE_LINE_BITS{1'b0}};


    // Update one word during a write hit

    if (write_hit_update)
    begin

        data_array_wdata =
            data_array_rdata;

        data_array_wdata[
            (word_select * `CACHE_DATA_WIDTH)
            +: `CACHE_DATA_WIDTH
        ] = cachereq_data_reg;

    end


    // Install line returned from memory

    else if (refill_update)
    begin

        data_array_wdata =
            refill_data_reg;

    end


    // Initialize a clean cache line

    else if (init_update)
    begin

        data_array_wdata =
            {`CACHE_LINE_BITS{1'b0}};

        data_array_wdata[
            (word_select * `CACHE_DATA_WIDTH)
            +: `CACHE_DATA_WIDTH
        ] = cachereq_data_reg;

    end

end


// Send complete victim line during write-back

assign mem_req_wdata =
       data_array_rdata;


// Select memory request address

assign mem_req_addr =
       evict_active
       ?
       {
           tag_array_rdata,
           cachereq_index_dec,
           {`CACHE_OFFSET_BITS{1'b0}}
       }
       :
       {
           cachereq_tag_dec,
           cachereq_index_dec,
           {`CACHE_OFFSET_BITS{1'b0}}
       };


endmodule