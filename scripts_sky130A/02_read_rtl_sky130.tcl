###############################################################################
# 02_read_rtl_sky130.tcl
#
# SKY130A / Fusion Compiler
#
# Physical top    : cache_io_wrapper_sky130
# Functional core : cache_top
###############################################################################

puts ""
puts "============================================================"
puts " SKY130A CACHE FLOW : 02 READ RTL"
puts "============================================================"

# ---------------------------------------------------------------------------
# 1. Project paths
# ---------------------------------------------------------------------------

set PROJ_ROOT "/home/vlsi/Documents/cache"
set RTL_DIR   "${PROJ_ROOT}/rtl"
set SDC_FILE  "${PROJ_ROOT}/SDC/cache.sdc"

# ---------------------------------------------------------------------------
# 2. Project-local FC-compatible SKY130 IO blackbox
# ---------------------------------------------------------------------------

set SKY130_IO_FC_BB \
    "${RTL_DIR}/sky130_fd_io_gpiov2_fc_blackbox.v"

# ---------------------------------------------------------------------------
# 3. Design names
# ---------------------------------------------------------------------------

set CORE_DESIGN_NAME "cache_top"
set DESIGN_NAME      "cache_io_wrapper_sky130"

# ---------------------------------------------------------------------------
# 4. RTL files
# ---------------------------------------------------------------------------

set RTL_FILES [list \
    "${RTL_DIR}/request_register.v" \
    "${RTL_DIR}/address_decoder.v" \
    "${RTL_DIR}/comparator.v" \
    "${RTL_DIR}/mux.v" \
    "${RTL_DIR}/tag_array.v" \
    "${RTL_DIR}/valid_array.v" \
    "${RTL_DIR}/dirty_array.v" \
    "${RTL_DIR}/data_array.v" \
    "${RTL_DIR}/cache_datapath.v" \
    "${RTL_DIR}/cache_controller.v" \
    "${RTL_DIR}/cache_top.v" \
    "${RTL_DIR}/cache_io_wrapper_sky130.v" \
]

# ---------------------------------------------------------------------------
# 5. File checks
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " FILE CHECK"
puts "------------------------------------------------------------"

set CACHE_CONFIG "${RTL_DIR}/cache_config.vh"

if {![file exists $CACHE_CONFIG]} {
    puts "ERROR: Missing:"
    puts "       $CACHE_CONFIG"
    error "cache_config.vh not found"
}

puts "OK: $CACHE_CONFIG"

if {![file exists $SKY130_IO_FC_BB]} {
    puts "ERROR: Missing:"
    puts "       $SKY130_IO_FC_BB"
    error "SKY130 FC IO blackbox not found"
}

puts "OK: $SKY130_IO_FC_BB"

foreach f $RTL_FILES {

    if {![file exists $f]} {
        puts "ERROR: RTL file not found:"
        puts "       $f"
        error "Missing RTL file"
    }

    puts "OK: $f"
}

# ---------------------------------------------------------------------------
# 6. Analyze SKY130 IO FC blackbox
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " ANALYZE SKY130 IO FC BLACKBOX"
puts "------------------------------------------------------------"

puts "Analyzing:"
puts "  $SKY130_IO_FC_BB"

analyze -format verilog $SKY130_IO_FC_BB

# ---------------------------------------------------------------------------
# 7. Analyze cache RTL
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " ANALYZE CACHE RTL"
puts "------------------------------------------------------------"

cd $RTL_DIR

foreach f $RTL_FILES {

    puts ""
    puts "Analyzing:"
    puts "  $f"

    analyze -format verilog $f
}

cd $PROJ_ROOT

# ---------------------------------------------------------------------------
# 8. Elaborate top-level wrapper
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " ELABORATE TOP"
puts "------------------------------------------------------------"

puts "Physical top:"
puts "  $DESIGN_NAME"

puts "Functional core:"
puts "  $CORE_DESIGN_NAME"

elaborate $DESIGN_NAME

# ---------------------------------------------------------------------------
# 9. Set top module
# ---------------------------------------------------------------------------
#
# IMPORTANT:
# This is intentionally AFTER elaborate.
#
# Earlier, set_top_module was called before a block existed and produced:
#
#   Current block is not defined. (DES-001)
#
# After successful elaboration, FC created:
#
#   cache_io_wrapper_sky130.design
#
# FC then requested set_top_module for this block.
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " SET TOP MODULE"
puts "------------------------------------------------------------"

puts "Top module:"
puts "  $DESIGN_NAME"

set_top_module $DESIGN_NAME

# ---------------------------------------------------------------------------
# 10. Select current design
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " CURRENT DESIGN"
puts "------------------------------------------------------------"

current_design $DESIGN_NAME

puts "Current design:"
puts "  [current_design]"

# ---------------------------------------------------------------------------
# 11. Read SDC
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " TIMING CONSTRAINTS"
puts "------------------------------------------------------------"

if {[file exists $SDC_FILE]} {

    puts "Reading:"
    puts "  $SDC_FILE"

    read_sdc $SDC_FILE

} else {

    puts "WARNING: SDC file not found:"
    puts "  $SDC_FILE"
}

# ---------------------------------------------------------------------------
# 12. Verify cache_top hierarchy
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " CACHE HIERARCHY CHECK"
puts "------------------------------------------------------------"

set CACHE_INSTANCES \
    [get_cells -hierarchical \
        -filter "ref_name =~ cache_top"]

puts "cache_top instances:"
puts "  [sizeof_collection $CACHE_INSTANCES]"

foreach_in_collection c $CACHE_INSTANCES {

    puts "  [get_object_name $c]"
}

# ---------------------------------------------------------------------------
# 13. Verify SKY130 IO hierarchy
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " SKY130 IO CHECK"
puts "------------------------------------------------------------"

set SKY130_IO_CELLS \
    [get_cells -hierarchical \
        -filter "ref_name =~ sky130_fd_io__top_*"]

puts "SKY130 IO instances:"
puts "  [sizeof_collection $SKY130_IO_CELLS]"

foreach_in_collection c $SKY130_IO_CELLS {

    set cname [get_object_name $c]
    set rname [get_attribute $c ref_name]

    puts "  $cname -> $rname"
}

# ---------------------------------------------------------------------------
# 14. Output directory
# ---------------------------------------------------------------------------

set OUTPUT_DIR "${PROJ_ROOT}/fc_output"

if {![file exists $OUTPUT_DIR]} {
    file mkdir $OUTPUT_DIR
}

# ---------------------------------------------------------------------------
# 15. Save elaborated RTL block
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# 15. Save elaborated RTL block
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " SAVE ELABORATED BLOCK"
puts "------------------------------------------------------------"

set RTL_BLOCK "${DESIGN_NAME}_rtl"

puts "Saving block:"
puts "  $RTL_BLOCK"

save_block -as $RTL_BLOCK

# ---------------------------------------------------------------------------
# 16. Completion
# ---------------------------------------------------------------------------

puts ""
puts "============================================================"
puts " 02_read_rtl_sky130.tcl COMPLETED"
puts "============================================================"
puts ""
puts "Physical top : $DESIGN_NAME"
puts "Core         : $CORE_DESIGN_NAME"
puts "============================================================"