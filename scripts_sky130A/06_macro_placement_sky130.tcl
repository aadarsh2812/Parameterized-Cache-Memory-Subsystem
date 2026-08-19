###############################################################################
# 06_macro_placement_sky130.tcl
###############################################################################
source "/home/vlsi/Documents/cache/scripts/design_setup_sky130.tcl"
current_design $DESIGN_NAME

if {$USE_SRAM_MACRO} {
    error "USE_SRAM_MACRO must remain 0 for this cache implementation."
}

set macros [get_cells -hierarchical -filter "is_hard_macro == true"]
puts "INFO: hard macros detected: [sizeof_collection $macros]"

if {[sizeof_collection $macros] != 0} {
    report_cells $macros > "${REPORT_DIR}/06_unexpected_macros.rpt"
    puts "WARNING: Unexpected hard macros exist; inspect before placement."
}

puts "INFO: Cache storage remains RTL arrays; no SRAM macro placement is performed."
save_block -as "${OUTPUT_DIR}/${DESIGN_NAME}_macro_checked"
