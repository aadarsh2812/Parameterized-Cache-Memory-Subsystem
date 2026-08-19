###############################################################################
# 08_clock_tree_sky130.tcl
###############################################################################
source "/home/vlsi/Documents/cache/scripts/design_setup_sky130.tcl"
current_design $DESIGN_NAME
read_sdc $SDC_FILE

# SKY130 HD clock buffers confirmed in the supplied configuration.
foreach c $CTS_CLK_BUFFERS {
    puts "INFO: CTS buffer candidate: $c"
}

# Use FC clock optimization without SAED14-specific CTS cell names.
clock_opt

report_clock_qor > "${REPORT_DIR}/08_clock_qor.rpt"
report_timing -delay_type max -max_paths 20 > "${REPORT_DIR}/08_setup_timing.rpt"
report_timing -delay_type min -max_paths 20 > "${REPORT_DIR}/08_hold_timing.rpt"

save_block -as "${OUTPUT_DIR}/${DESIGN_NAME}_cts"
