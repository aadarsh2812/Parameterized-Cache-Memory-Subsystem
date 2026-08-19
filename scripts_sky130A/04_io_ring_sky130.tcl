###############################################################################
# 04_io_ring_sky130.tcl
###############################################################################
source "/home/vlsi/Documents/cache/scripts/design_setup_sky130.tcl"
current_design $DESIGN_NAME

# Verify that the wrapper instantiated real SKY130 IO references.
set io_cells [get_cells -hierarchical -filter "ref_name =~ sky130_fd_io__top_*"]
puts "INFO: SKY130 top IO instances found: [sizeof_collection $io_cells]"
if {[sizeof_collection $io_cells] == 0} {
    error "No SKY130 IO instances found. Fix cache_io_wrapper_sky130.v before continuing."
}

foreach_in_collection c $io_cells {
    puts "IO: [get_object_name $c] -> [get_attribute $c ref_name]"
}

# Do not use SAED14 pad names. Exact coordinates/orientations depend on the
# actual pad count and cell dimensions. Keep the verified instance set and
# report it for placement.
report_cells $io_cells > "${REPORT_DIR}/04_io_cells.rpt"
save_block -as "${OUTPUT_DIR}/${DESIGN_NAME}_io"
