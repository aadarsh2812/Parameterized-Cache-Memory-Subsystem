###############################################################################
## config/design_setup.tcl
## MASTER FLOW CONFIGURATION — sourced at the top of EVERY script (01..11)
##
## PURPOSE:  Single source of truth for all paths, design parameters, and
##           tool options.  Edit ONLY this file when:
##             - The EDK location changes
##             - You want a different SRAM macro
##             - You want a different clock frequency
##             - You want a different die size
##
## SAED14nm EDK root (verified on this machine):
##   /home/vlsi/Synopsys/Fusa_EDK/SAED14nm_EDK_08_2025/SAED14_EDK
##
## Tiny-GPU memory map (design decision):
##   Program memory : SRAM1RW256x32  (256 words x 32-bit)
##                    Only [15:0] bits used for 16-bit instructions.
##   Data memory    : SRAM1RW256x32  (256 words x 8-bit effective)
##                    Only [7:0] bits used; [31:8] tied to 0.
##   Both SRAMs are instantiated in src/sram_wrapper.sv which wraps the
##   SAED SRAM macros behind the GPU's external memory interface.
##
## Register file note:
##   Per-thread register files (16x8-bit FFs) stay as standard cells.
###############################################################################

## =============================================================================
## SECTION 1 - Design Identity
## =============================================================================

set DESIGN_NAME    "gpu_top"              ;# Top-level module (gpu_top.sv wraps gpu)
set DESIGN_LIB     "tiny_gpu.ndm"         ;# FC internal NDM work library name

## =============================================================================
## SECTION 2 - Directory Structure
## =============================================================================

## Project root (absolute - derived from this script location)
set SCRIPT_DIR  [file normalize [file dirname [info script]]]
set PROJ_ROOT   [file normalize "${SCRIPT_DIR}/.."]

## Output directories (created by run_all.sh before running scripts)
set OUTPUT_DIR  "${PROJ_ROOT}/output"
set REPORT_DIR  "${PROJ_ROOT}/reports"
set LOG_DIR     "${PROJ_ROOT}/logs"

## =============================================================================
## SECTION 3 - SAED14nm EDK Root Paths (verified 2025-08 on this machine)
## =============================================================================

set EDK_ROOT   "/home/vlsi/Synopsys/Fusa_EDK/SAED14nm_EDK_08_2025/SAED14_EDK"

## Sub-kit roots
set EDK_RVT    "${EDK_ROOT}/SAED14nm_EDK_STD_RVT"
set EDK_LVT    "${EDK_ROOT}/SAED14nm_EDK_STD_LVT"
set EDK_IO_WB  "${EDK_ROOT}/SAED14nm_EDK_IO_WB"
set EDK_SRAM   "${EDK_ROOT}/SAED14nm_EDK_SRAM"
set EDK_TECH   "${EDK_ROOT}/SAED14nm_EDK_TECH_DATA"

## =============================================================================
## SECTION 4 - Technology Files
## =============================================================================

## Technology file: 1-poly 9-metal SAED14nm (1P9M)
set TF_FILE        "${EDK_TECH}/tf/saed14nm_1p9m.tf"

## TLUplus RC tables (parasitic extraction)
##   Cmax = slow corner (worst setup) -> used for setup analysis
##   Cmin = fast corner (worst hold)  -> used for hold analysis
set TLUPLUS_MAX    "${EDK_TECH}/tlup/saed14nm_1p9m_Cmax.tlup"
set TLUPLUS_MIN    "${EDK_TECH}/tlup/saed14nm_1p9m_Cmin.tlup"
set TLUPLUS_NOM    "${EDK_TECH}/tlup/saed14nm_1p9m_Cnom.tlup"

## Layer name -> GDS layer number mapping (required for TLUplus and GDS stream)
set LAYER_MAP_FILE "${EDK_TECH}/map/saed14nm_tf_itf_tluplus.map"
set GDS_LAYER_MAP  "${EDK_TECH}/map/saed14nm_1p9m_gdsin_gdsout.map"

## =============================================================================
## SECTION 5 - Standard Cell Libraries
## =============================================================================
## Corner naming convention in SAED14nm files:
##   ss0p72v125c = slow-slow, 0.72V, 125C  -> worst setup (use for max timing)
##   ff0p88vm40c = fast-fast, 0.88V, -40C  -> worst hold  (use for min timing)
##   tt0p8v25c   = typical, 0.8V, 25C      -> balanced
##
## NOTE: SAED14nm 08/2025 does NOT have saed14rvt_base_ss0p72vm40c or
##       saed14rvt_cg_ss0p72vm40c - the correct slow corner file is
##       saed14rvt_base_ss0p72v125c / saed14rvt_cg_ss0p72v125c.

## -- 5.1  RVT standard cell library ----------------------------------------
## Liberty: base (all logic cells) + cg (clock-gate cells for -gate_clock)
set STDCELL_RVT_LIB_MAX [list \
    "${EDK_RVT}/liberty/nldm/base/saed14rvt_base_ss0p72v125c.lib" \
    "${EDK_RVT}/liberty/nldm/cg/saed14rvt_cg_ss0p72v125c.lib"   \
]

set STDCELL_RVT_LIB_MIN [list \
    "${EDK_RVT}/liberty/nldm/base/saed14rvt_base_ff0p88vm40c.lib" \
    "${EDK_RVT}/liberty/nldm/cg/saed14rvt_cg_ff0p88vm40c.lib"   \
]

## NDM reference libraries - used for physical synthesis in Fusion Compiler
set STDCELL_RVT_NDM [list \
    "${EDK_RVT}/ndm/saed14rvt_base_frame_timing.ndm" \
    "${EDK_RVT}/ndm/saed14rvt_cg_frame_timing.ndm"  \
]

## LEF abstract (FC prefers NDM but can use LEF for legacy compatibility)
set STDCELL_RVT_LEF    "${EDK_RVT}/lef/saed14rvt.lef"

## GDS (merged into final GDSII in step 11)
set STDCELL_RVT_GDS    "${EDK_RVT}/gds/saed14rvt.gds"

## -- 5.2  LVT standard cell library ----------------------------------------
## LVT cells: faster, higher leakage - used for hold fixing and critical paths
set STDCELL_LVT_LIB_MAX [list \
    "${EDK_LVT}/liberty/nldm/base/saed14lvt_base_ss0p72v125c.lib" \
    "${EDK_LVT}/liberty/nldm/cg/saed14lvt_cg_ss0p72v125c.lib"   \
]

set STDCELL_LVT_LIB_MIN [list \
    "${EDK_LVT}/liberty/nldm/base/saed14lvt_base_ff0p88vm40c.lib" \
    "${EDK_LVT}/liberty/nldm/cg/saed14lvt_cg_ff0p88vm40c.lib"   \
]

set STDCELL_LVT_NDM [list \
    "${EDK_LVT}/ndm/saed14lvt_base_frame_timing.ndm" \
    "${EDK_LVT}/ndm/saed14lvt_cg_frame_timing.ndm"  \
]

set STDCELL_LVT_LEF    "${EDK_LVT}/lef/saed14lvt.lef"
set STDCELL_LVT_GDS    "${EDK_LVT}/gds/saed14lvt.gds"

## -- 5.3  Physical-only cell names (verified from SAED14nm RVT LEF) ---------
## Tap cells confirmed in saed14rvt.lef:
##   SAEDRVT14_TAPPP10  = P+ substrate tap, 10 sites wide (primary well tap)
##   SAEDRVT14_TAPPN    = N-well tap
##   SAEDRVT14_TAPDS    = dual-stripe tap
## Decap cells confirmed in saed14rvt.lef:
##   SAEDRVT14_DCAP_V4_8   = 8-site decoupling cap
##   SAEDRVT14_DCAP_V4_16  = 16-site decoupling cap
##   SAEDRVT14_DCAP_V4_32  = 32-site decoupling cap
##   SAEDRVT14_DCAP_V4_64  = 64-site decoupling cap
## Note: SAED14nm has no separate endcap cell. TAPPP/TAPPN act as endcap+welltap.
##       FC insert_boundary_cell will use lib_cell_purpose=endcap tagged cells.
set WELLTAP_CELL   "SAEDRVT14_TAPPP10"
set WELLTAP_N_CELL "SAEDRVT14_TAPPN"
set DECAP_CELL     "SAEDRVT14_DCAP_V4_8"
set DECAP_CELL_LIST [list \
    "SAEDRVT14_DCAP_V4_8"  \
    "SAEDRVT14_DCAP_V4_16" \
    "SAEDRVT14_DCAP_V4_32" \
]

## =============================================================================
## SECTION 6 - IO Pad Library (wire-bond variant)
## =============================================================================
## Cell names confirmed from saed14io_wb.lef MACRO section:
##   VDD_TB / VDD_LR      SIZE 37x108 / 108x39 um - core power pad
##   VSS_TB / VSS_LR      SIZE 37x108 / 108x39 um - core ground pad
##   VDDIO_TB / VDDIO_LR  - IO power  pad (1.8V)
##   VSSIO_TB / VSSIO_LR  - IO ground pad (1.8V)
##   I0818_TB / I0818_LR  - digital input pad (0.8V core / 1.8V IO)
##   ISH0818_TB/ISH0818_LR - input pad with Schmitt trigger
##   DI0818_TB / DI0818_LR - digital output pad
##   BI0818_TB / BI0818_LR - bidirectional pad
##   BISH0818_TB/BISH0818_LR - bidir with Schmitt trigger
##   CORNER                 SIZE 108x108 um - corner cell
##   FILLER{1,2,3,4,8,16,32}_TB/LR - IO ring filler cells

set IO_CORNER_CELL   "CORNER"
set IO_IN_CELL_TB    "I0818_TB"
set IO_IN_CELL_LR    "I0818_LR"
set IO_IN_SCH_TB     "ISH0818_TB"
set IO_IN_SCH_LR     "ISH0818_LR"
set IO_OUT_CELL_TB   "DI0818_TB"
set IO_OUT_CELL_LR   "DI0818_LR"
set IO_BIDIR_CELL_TB "BI0818_TB"
set IO_BIDIR_CELL_LR "BI0818_LR"
set IO_VDD_CELL_TB   "VDD_TB"
set IO_VDD_CELL_LR   "VDD_LR"
set IO_VSS_CELL_TB   "VSS_TB"
set IO_VSS_CELL_LR   "VSS_LR"
set IO_VDDIO_CELL_TB "VDDIO_TB"
set IO_VDDIO_CELL_LR "VDDIO_LR"
set IO_VSSIO_CELL_TB "VSSIO_TB"
set IO_VSSIO_CELL_LR "VSSIO_LR"

## IO NDM reference library (for FC physical synthesis)
## NOTE: saed14io_wb.mw is Milkyway format (not valid for create_lib -ref_libs)
##       The actual NDM files are in the ndm/ subdirectory:
##         saed14io_wb_frame_timing.ndm  (geometry + timing)
##         saed14io_wb_frame_only.ndm    (geometry only)
set IO_NDM           "${EDK_IO_WB}/ndm/saed14io_wb_frame_timing.ndm"

## IO Liberty timing models (corners confirmed from directory listing)
##   ss0p72v125c_1p62v = slow core (0.72V) + slow IO (1.62V) -> worst setup
##   ff0p88vm40c_1p96v = fast core (0.88V) + fast IO (1.96V) -> worst hold
set IO_LIB_MAX       "${EDK_IO_WB}/liberty/nldm/saed14_io_wb_ss0p72v125c_1p62v.lib"
set IO_LIB_MIN       "${EDK_IO_WB}/liberty/nldm/saed14_io_wb_ff0p88vm40c_1p96v.lib"

## IO LEF abstract (pin shapes, ring metal layers)
set IO_LEF           "${EDK_IO_WB}/lef/saed14io_wb.lef"

## IO GDS (merged into final GDSII in step 11)
set IO_GDS           "${EDK_IO_WB}/gds/saed14io_wb.gds"

## IO Verilog simulation model (used as black-box in synthesis)
set IO_VERILOG       "${EDK_IO_WB}/verilog/saed14_io_wb.v"

## =============================================================================
## SECTION 7 - SRAM Macro
## =============================================================================
## Chosen macro: SRAM1RW256x32
##   Configuration: 256 words x 32 bits (single-port, read-write)
##   Actual dimensions from saed14sram.lef: SIZE 136.012 BY 267 um
##
## Usage in tiny-gpu:
##   inst_prog_sram: program memory  - 256 x 32 (only bits[15:0] used for 16b instr)
##   inst_data_sram: data memory     - 256 x 32 (only bits[7:0]  used for 8b data)
##
## SRAM1RW256x32 port map (from saed14sram.v):
##   ADDR[7:0]   - address input (8-bit for 256 words)
##   DATA[31:0]  - write data
##   Q[31:0]     - read data output
##   CEn         - chip enable (active low)
##   WEn         - write enable (active low)
##   OEn         - output enable (active low) -- tie to 0 for always-enabled
##   CLK         - clock input (rising edge)

set SRAM_CELL_NAME   "SRAM1RW256x32"
set SRAM_WIDTH_UM    136.012            ;# from LEF SIZE field (um)
set SRAM_HEIGHT_UM   267.0             ;# from LEF SIZE field (um)

## SRAM NDM (geometry + timing for place & route)
set SRAM_NDM         "${EDK_SRAM}/ndm/saed14sram_frame_timing.ndm"

## SRAM Liberty timing models (confirmed from directory listing)
set SRAM_LIB_MAX     "${EDK_SRAM}/liberty/nldm/saed14sram_ss0p72v125c.lib"
set SRAM_LIB_MIN     "${EDK_SRAM}/liberty/nldm/saed14sram_ff0p88vm40c.lib"

## SRAM LEF abstract
set SRAM_LEF         "${EDK_SRAM}/lef/saed14sram.lef"

## SRAM GDS (merged into final GDSII in step 11)
set SRAM_GDS         "${EDK_SRAM}/gds/saed14sram.gds"

## SRAM Verilog simulation model (black-box in synthesis)
set SRAM_VERILOG     "${EDK_SRAM}/verilog/saed14sram.v"

## =============================================================================
## SECTION 8 - RTL Source Files
## =============================================================================
## Analyze order: bottom of hierarchy first, top-level last.
## sram_wrapper.sv (SRAM black-box instantiation) before gpu.sv.
## gpu_top.sv is the chip top that adds IO ring connection logic.

set RTL_DIR   "${PROJ_ROOT}/src"

set RTL_FILES [list \
    "${RTL_DIR}/alu.sv"          \
    "${RTL_DIR}/lsu.sv"          \
    "${RTL_DIR}/registers.sv"    \
    "${RTL_DIR}/pc.sv"           \
    "${RTL_DIR}/fetcher.sv"      \
    "${RTL_DIR}/decoder.sv"      \
    "${RTL_DIR}/scheduler.sv"    \
    "${RTL_DIR}/controller.sv"   \
    "${RTL_DIR}/dispatch.sv"     \
    "${RTL_DIR}/dcr.sv"          \
    "${RTL_DIR}/core.sv"         \
    "${RTL_DIR}/gpu.sv"          \
    "${RTL_DIR}/sram_wrapper.sv" \
    "${RTL_DIR}/gpu_top.sv"      \
]

## =============================================================================
## SECTION 9 - Constraints (SDC)
## =============================================================================

set SDC_FILE         "${PROJ_ROOT}/constraints/gpu.sdc"
set CLK_PORT_NAME    "clk"
set CLK_PERIOD_NS     5.0      ;# 5 ns = 200 MHz
set CLK_SKEW_NS       0.050    ;# 50 ps target global clock skew

## =============================================================================
## SECTION 10 - Floorplan Geometry
## =============================================================================
## Die sizing rationale:
##   Two SRAM macros side by side in Y-direction:
##     SRAM footprint: 136 um W x 267 um H each
##     Two SRAMs:      136 um W x 534 um H total (stacked vertically)
##     With margin:    ~156 um W x ~554 um H (with 10um halo each)
##
##   Standard cell area estimate (60% utilization):
##     tiny-gpu 2-core: ~20,000-40,000 cells x ~0.5 um2/cell = ~20,000 um2
##     Core needed = 20,000 / 0.60 = 33,333 um2
##     Plus SRAM area: 2 x (136 x 267) = 72,624 um2
##     Total core = ~106,000 um2
##
##   Core dimensions: 524 x 634 um (= 524 * 634 = 332,216 um2, provides margin)
##   IO ring depth: 108 um (CORNER cell is 108x108 um)
##   Actual cell sizes from saed14io_fc.lef (not saed14io_wb.lef):
##     I0818_TB / VDD_TB / VSS_TB etc.   : SIZE 37 x 100  um (W x H)
##     I0818_LR / VDD_LR / VSS_LR etc.  : SIZE 100 x 39  um (W x H)
##     CORNER                             : SIZE 100 x 100 um
##     FILLER1_TB                         : SIZE 0.74 x 100 um (base filler unit)
##
##   Pad count (corrected):
##     Bottom/Top: (740 - 200) / 37 = 14.6 -> 14 pads + 96 um filler
##     Left/Right: (850 - 200) / 39 = 16.7 -> 16 pads + 26 um filler

set DIE_WIDTH          720      ;# um
set DIE_HEIGHT         820      ;# um
set IO_RING_DEPTH      100      ;# um (= actual CORNER height = TB/LR cell depth per LEF)

set CORE_LLX           [expr {$IO_RING_DEPTH}]
set CORE_LLY           [expr {$IO_RING_DEPTH}]
set CORE_URX           [expr {$DIE_WIDTH  - $IO_RING_DEPTH}]
set CORE_URY           [expr {$DIE_HEIGHT - $IO_RING_DEPTH}]
set CORE_UTILIZATION   0.70     ;# 70% standard-cell area target

## =============================================================================
## SECTION 11 - Power/Ground Net Names
## =============================================================================

set VDD_NET    "VDD"
set VSS_NET    "VSS"
set VDDIO_NET  "VDDIO"
set VSSIO_NET  "VSSIO"

## =============================================================================
## SECTION 12 - Power Routing Metal Layers (SAED14nm 1P9M stack)
## =============================================================================
## M1       = cell internal VDD/VSS rails (horizontal, inside each row)
## M2 - M7  = signal routing (FC manages automatically)
## M8       = horizontal power stripes
## M9       = vertical   power stripes
## Layer names MUST match saed14nm_1p9m.tf exactly.

set POWER_LAYER_H      "M8"
set POWER_LAYER_V      "M9"
set MAX_ROUTING_LAYER  "M7"    ;# signal routing ceiling (below power layers)

## =============================================================================
## SECTION 13 - Clock Tree Synthesis Settings
## =============================================================================

## NDR rule name (defined in 08_clock_tree.tcl)
set CTS_NDR_NAME     "cts_2w2s"

## Clock buffers from RVT library (confirmed names: SAEDRVT14_BUF_S_*)
set CTS_CLK_BUFFERS  [list \
    "SAEDRVT14_BUF_S_2"  \
    "SAEDRVT14_BUF_S_4"  \
    "SAEDRVT14_BUF_S_8"  \
    "SAEDRVT14_BUF_S_16" \
]

## =============================================================================
## SECTION 14 - DRC/LVS Signoff Rule Decks (ICV)
## =============================================================================
## Confirmed paths from directory listing of SAED14nm_EDK_TECH_DATA:
##   icv_drc/saed14nm_1p9m_drc_rules.rs     - DRC runset
##   icv_lvs/saed14nm_1p9m_lvs_runset.rs    - LVS runset

set ICV_DRC_RULES  "${EDK_TECH}/icv_drc/saed14nm_1p9m_drc_rules.rs"
set ICV_LVS_RULES  "${EDK_TECH}/icv_lvs/saed14nm_1p9m_lvs_runset.rs"

## =============================================================================
## SECTION 15 - Output File Names
## =============================================================================

set GDS_OUT      "${OUTPUT_DIR}/${DESIGN_NAME}_final.gds"
set DEF_OUT      "${OUTPUT_DIR}/${DESIGN_NAME}_final.def"
set NETLIST_OUT  "${OUTPUT_DIR}/${DESIGN_NAME}_final.v"

## =============================================================================
## SECTION 16 - PVT Corner Tag
## =============================================================================

set CORNER    "ss_0p72v_125c"

## =============================================================================
## SECTION 17 - Consolidated Reference Library List (for create_lib)
## =============================================================================
## FC reads NDM as primary reference; SRAM NDM is also available.
## The IO milkyway (.mw) is an older MW library accepted by FC.

set ALL_REF_LIBS [concat \
    $STDCELL_RVT_NDM  \
    $STDCELL_LVT_NDM  \
    [list $IO_NDM]    \
    [list $SRAM_NDM]  \
]

## =============================================================================
## SECTION 18 - Path Sanity Check
## =============================================================================
proc check_path {varname path} {
    if {![file exists $path]} {
        puts "WARNING: \$${varname} path does not exist: ${path}"
    }
}

check_path TF_FILE         $TF_FILE
check_path TLUPLUS_MAX     $TLUPLUS_MAX
check_path LAYER_MAP_FILE  $LAYER_MAP_FILE
check_path GDS_LAYER_MAP   $GDS_LAYER_MAP
check_path STDCELL_RVT_LEF $STDCELL_RVT_LEF
check_path STDCELL_LVT_LEF $STDCELL_LVT_LEF
check_path IO_LEF          $IO_LEF
check_path SRAM_LEF        $SRAM_LEF
check_path ICV_DRC_RULES   $ICV_DRC_RULES
check_path ICV_LVS_RULES   $ICV_LVS_RULES

puts "INFO: design_setup.tcl loaded"
puts "INFO:   DESIGN     = ${DESIGN_NAME}"
puts "INFO:   CORNER     = ${CORNER}"
puts "INFO:   CLK PERIOD = ${CLK_PERIOD_NS} ns ([expr {int(1000/$CLK_PERIOD_NS)}] MHz)"
puts "INFO:   DIE        = ${DIE_WIDTH} x ${DIE_HEIGHT} um"
puts "INFO:   CORE       = (${CORE_LLX},${CORE_LLY}) -> (${CORE_URX},${CORE_URY})"
puts "INFO:   UTIL       = [expr {int($CORE_UTILIZATION*100)}]%"
