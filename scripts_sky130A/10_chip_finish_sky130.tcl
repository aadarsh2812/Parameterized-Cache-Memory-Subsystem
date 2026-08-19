###############################################################################
# 10_chip_finish_sky130.tcl
###############################################################################
source "/home/vlsi/Documents/cache/scripts/design_setup_sky130.tcl"
current_design $DESIGN_NAME

# Final physical optimization and connectivity checks.
route_opt

report_qor > "${REPORT_DIR}/10_final_qor.rpt"
report_area > "${REPORT_DIR}/10_final_area.rpt"
report_timing -delay_type max -max_paths 50 > "${REPORT_DIR}/10_final_setup.rpt"
report_timing -delay_type min -max_paths 50 > "${REPORT_DIR}/10_final_hold.rpt"
report_design > "${REPORT_DIR}/10_final_design.rpt"

save_block -as "${OUTPUT_DIR}/${DESIGN_NAME}_final"
