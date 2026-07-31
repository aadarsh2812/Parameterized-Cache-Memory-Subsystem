`timescale 1ns / 1ps
`include "cache_config.vh"
//==========================================================
// Module Name : cache_controller
// Project     : Parameterized Cache Memory Subsystem
// Author      : AADARSH K.A.S
// Description : Controls cache operations including hit,
//               miss, eviction, refill and memory access.
//==========================================================
module cache_controller
(
    input clk,
    input reset,

    // CPU interface
    input cpu_req_valid,
    output reg cpu_req_ready,

    input cpu_resp_ready,
    output reg cpu_resp_valid,

    input [`CACHE_TYPE_WIDTH-1:0] cachereq_type_reg,

    // Cache status
    input tag_match,
    input valid_array_rdata,
    input dirty_array_rdata,

    // Memory interface
    input mem_req_ready,
    input mem_resp_valid,

    output reg mem_req_valid,
    output reg mem_req_write,

    // Request register
    output reg request_register_load,

    // Tag array
    output reg tag_array_ren,
    output reg tag_array_wen,

    // Valid array
    output reg valid_array_ren,
    output reg valid_array_wen,

    // Dirty array
    output reg dirty_array_ren,
    output reg dirty_array_wen,

    // Data array
    output reg data_array_ren,
    output reg data_array_wen,

    // Datapath control
    output reg write_hit_update,
    output reg refill_update,
    output reg evict_active,
    output reg init_update
);


// Cache request types

localparam CACHE_REQ_READ  = 2'b00;
localparam CACHE_REQ_WRITE = 2'b01;
localparam CACHE_REQ_INIT  = 2'b10;


// FSM states

localparam STATE_IDLE              = 4'd0;
localparam STATE_TAG_CHECK         = 4'd1;
localparam STATE_LOOKUP_WAIT       = 4'd2;
localparam STATE_INIT_DATA_ACCESS  = 4'd3;
localparam STATE_READ_DATA_ACCESS  = 4'd4;
localparam STATE_WRITE_DATA_ACCESS = 4'd5;
localparam STATE_EVICT_PREPARE     = 4'd6;
localparam STATE_EVICT_REQUEST     = 4'd7;
localparam STATE_EVICT_WAIT        = 4'd8;
localparam STATE_REFILL_REQUEST    = 4'd9;
localparam STATE_REFILL_WAIT       = 4'd10;
localparam STATE_REFILL_UPDATE     = 4'd11;
localparam STATE_WAIT              = 4'd12;


// State registers

reg [3:0] current_state;
reg [3:0] next_state;


// State register

always @(posedge clk)
begin
    if (reset)
    begin
        current_state <= STATE_IDLE;
    end
    else
    begin
        current_state <= next_state;
    end
end


// Next-state logic

always @(*)
begin

    next_state = current_state;

    case (current_state)

        // Wait for a new CPU request
        STATE_IDLE:
        begin
            if (cpu_req_valid)
            begin
                next_state = STATE_TAG_CHECK;
            end
        end


        // Start reading cache arrays
        STATE_TAG_CHECK:
        begin
            next_state = STATE_LOOKUP_WAIT;
        end


        // Check hit, miss and dirty status
        STATE_LOOKUP_WAIT:
        begin

            // Initialization request
            if (cachereq_type_reg == CACHE_REQ_INIT)
            begin
                next_state = STATE_INIT_DATA_ACCESS;
            end

            // Cache hit
            else if (tag_match && valid_array_rdata)
            begin

                if (cachereq_type_reg == CACHE_REQ_READ)
                begin
                    next_state = STATE_READ_DATA_ACCESS;
                end

                else if (cachereq_type_reg == CACHE_REQ_WRITE)
                begin
                    next_state = STATE_WRITE_DATA_ACCESS;
                end

            end

            // Cache miss
            else
            begin

                // Dirty victim needs write-back
                if (valid_array_rdata && dirty_array_rdata)
                begin
                    next_state = STATE_EVICT_PREPARE;
                end

                // Clean or invalid victim can be replaced
                else
                begin
                    next_state = STATE_REFILL_REQUEST;
                end

            end

        end


        // Initialize selected cache line
        STATE_INIT_DATA_ACCESS:
        begin
            next_state = STATE_WAIT;
        end


        // Read requested data
        STATE_READ_DATA_ACCESS:
        begin
            next_state = STATE_WAIT;
        end


        // Update cache line
        STATE_WRITE_DATA_ACCESS:
        begin
            next_state = STATE_WAIT;
        end


        // Prepare victim line for write-back
        STATE_EVICT_PREPARE:
        begin
            next_state = STATE_EVICT_REQUEST;
        end


        // Send victim line to memory
        STATE_EVICT_REQUEST:
        begin
            if (mem_req_ready)
            begin
                next_state = STATE_EVICT_WAIT;
            end
        end


        // Wait for write-back completion
        STATE_EVICT_WAIT:
        begin
            if (mem_resp_valid)
            begin
                next_state = STATE_REFILL_REQUEST;
            end
        end


        // Request new cache line from memory
        STATE_REFILL_REQUEST:
        begin
            if (mem_req_ready)
            begin
                next_state = STATE_REFILL_WAIT;
            end
        end


        // Wait for refill data
        STATE_REFILL_WAIT:
        begin
            if (mem_resp_valid)
            begin
                next_state = STATE_REFILL_UPDATE;
            end
        end


        // Install refill line
        STATE_REFILL_UPDATE:
        begin
            next_state = STATE_TAG_CHECK;
        end


        // Wait for CPU to accept response
        STATE_WAIT:
        begin
            if (cpu_resp_ready)
            begin
                next_state = STATE_IDLE;
            end
        end


        // Recover from invalid state
        default:
        begin
            next_state = STATE_IDLE;
        end

    endcase

end


// Control signal generation

always @(*)
begin

    // Default values

    cpu_req_ready         = 1'b0;
    cpu_resp_valid        = 1'b0;

    request_register_load = 1'b0;

    tag_array_ren         = 1'b0;
    tag_array_wen         = 1'b0;

    valid_array_ren       = 1'b0;
    valid_array_wen       = 1'b0;

    dirty_array_ren       = 1'b0;
    dirty_array_wen       = 1'b0;

    data_array_ren        = 1'b0;
    data_array_wen        = 1'b0;

    mem_req_valid         = 1'b0;
    mem_req_write         = 1'b0;

    write_hit_update      = 1'b0;
    refill_update         = 1'b0;
    evict_active          = 1'b0;
    init_update           = 1'b0;


    case (current_state)

        // Accept a new CPU request
        STATE_IDLE:
        begin

            cpu_req_ready = 1'b1;

            if (cpu_req_valid && cpu_req_ready)
            begin
                request_register_load = 1'b1;
            end

        end


        // Read tag, valid, dirty and data arrays
        STATE_TAG_CHECK:
        begin

            tag_array_ren   = 1'b1;
            valid_array_ren = 1'b1;
            dirty_array_ren = 1'b1;
            data_array_ren  = 1'b1;

        end


        // Array outputs are checked in next-state logic
        STATE_LOOKUP_WAIT:
        begin
        end


        // Initialize selected cache line
        STATE_INIT_DATA_ACCESS:
        begin

            tag_array_wen   = 1'b1;
            valid_array_wen = 1'b1;
            dirty_array_wen = 1'b1;
            data_array_wen  = 1'b1;
            init_update     = 1'b1;

        end


        // Read data from cache
        STATE_READ_DATA_ACCESS:
        begin

            data_array_ren = 1'b1;

        end


        // Update cache line and set dirty bit
        STATE_WRITE_DATA_ACCESS:
        begin

            data_array_wen   = 1'b1;
            dirty_array_wen  = 1'b1;

            write_hit_update = 1'b1;

        end


        // Read victim tag and data
        STATE_EVICT_PREPARE:
        begin

            tag_array_ren  = 1'b1;
            data_array_ren = 1'b1;

        end


        // Send dirty victim to memory
        STATE_EVICT_REQUEST:
        begin

            mem_req_valid = 1'b1;
            mem_req_write = 1'b1;

            evict_active  = 1'b1;

        end


        // Wait for memory response
        STATE_EVICT_WAIT:
        begin
        end


        // Request missing line from memory
        STATE_REFILL_REQUEST:
        begin

            mem_req_valid = 1'b1;
            mem_req_write = 1'b0;

        end


        // Wait for refill response
        STATE_REFILL_WAIT:
        begin
        end


        // Install refill data
        STATE_REFILL_UPDATE:
        begin

            tag_array_wen   = 1'b1;
            valid_array_wen = 1'b1;
            dirty_array_wen = 1'b1;
            data_array_wen  = 1'b1;

            refill_update   = 1'b1;

        end


        // Send response to CPU
        STATE_WAIT:
        begin

            cpu_resp_valid = 1'b1;

        end


        default:
        begin
        end

    endcase

end

endmodule