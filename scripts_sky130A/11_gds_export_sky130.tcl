###############################################################################
# 11_gds_export_sky130.tcl
###############################################################################
source "/home/vlsi/Documents/cache/scripts/design_setup_sky130.tcl"
current_design $DESIGN_NAME

# Write the final logical/physical interchange files first.
write_def -output $DEF_OUT
write_verilog -output $NETLIST_OUT

puts "INFO: DEF  = $DEF_OUT"
puts "INFO: NET  = $NETLIST_OUT"
puts "INFO: IO GDS = $IO_GDS"
puts "INFO: STD GDS = $STDCELL_GDS"

# IMPORTANT:
# SKY130A does not contain an FC NDM in the supplied tree. The exact FC GDS
# stream-out command/options depend on how the SKY130 physical library is
# prepared in your installed FC/Library-Compiler environment.
#
# Do not silently invent a layer-map or NDM command here.
# If write_gds is supported by this FC session, use the PDK's actual layer
# map/technology configuration before streaming.
if {[llength [info commands write_gds]]} {
    puts "INFO: write_gds command is available in this FC session."
    puts "INFO: GDS stream-out is intentionally gated until the physical"
    puts "      SKY130 library/layer-map setup has been verified."
} else {
    puts "WARNING: write_gds is not available in this FC session."
}

puts "INFO: Final DEF/netlist export completed."
