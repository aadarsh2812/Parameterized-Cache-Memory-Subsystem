`ifndef CACHE_CONFIG_VH
`define CACHE_CONFIG_VH

//============================================================
// File Name   : cache_config.vh
// Project     : Parameterized Cache Memory Subsystem
// Author      : AADARSH K.A.S
// Description : Global cache configuration.
//============================================================

// User Configuration

`define CACHE_ADDR_WIDTH      32
`define CACHE_DATA_WIDTH      32
`define CACHE_OPAQUE_WIDTH    8
`define CACHE_TYPE_WIDTH      2
`define CACHE_LEN_WIDTH       2

`define CACHE_SIZE            256      // Bytes
`define CACHE_LINE_SIZE       16       // Bytes
`define CACHE_NUM_BANKS       1

// Derived Configuration

`define CACHE_NUM_LINES       (`CACHE_SIZE / `CACHE_LINE_SIZE)
`define CACHE_LINES_PER_BANK  (`CACHE_NUM_LINES / `CACHE_NUM_BANKS)

`define CACHE_OFFSET_BITS     $clog2(`CACHE_LINE_SIZE)
`define CACHE_INDEX_BITS      $clog2(`CACHE_LINES_PER_BANK)

`define CACHE_TAG_BITS \
(`CACHE_ADDR_WIDTH - `CACHE_OFFSET_BITS - `CACHE_INDEX_BITS)

`endif

