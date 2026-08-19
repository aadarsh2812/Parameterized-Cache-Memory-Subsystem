###############################################################################
# 05_power_plan_sky130.tcl
###############################################################################
source "/home/vlsi/Documents/cache/scripts/design_setup_sky130.tcl"
current_design $DESIGN_NAME

# SKY130 HD standard cells use VPWR/VGND; IO domains are VDDIO/VSSIO.
# Create logical PG nets only if the corresponding ports/pins exist.
foreach n [list $VDD_NET $VSS_NET $VDDIO_NET $VSSIO_NET] {
    puts "INFO: power net candidate: $n"
}

puts "INFO: Physical power-ring construction is deferred until actual IO pad"
puts "      PG pin names and pad connections are confirmed in the wrapper."
report_net -power > "${REPORT_DIR}/05_power_nets.rpt"
save_block -as "${OUTPUT_DIR}/${DESIGN_NAME}_power"
