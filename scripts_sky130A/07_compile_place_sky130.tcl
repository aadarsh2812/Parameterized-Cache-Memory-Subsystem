###############################################################################
# 07_compile_place_sky130.tcl
###############################################################################
source "/home/vlsi/Documents/cache/scripts/design_setup_sky130.tcl"
current_design $DESIGN_NAME
read_sdc $SDC_FILE

# Use Fusion Compiler physical synthesis/placement.
# No SAED cell names are supplied.
set_app_options -name place.coarse.continue_on_missing_scandef -value true

compile_fusion -to placement

report_qor > "${REPORT_DIR}/07_qor.rpt"
report_area > "${REPORT_DIR}/07_area.rpt"
report_congestion > "${REPORT_DIR}/07_congestion.rpt"

save_block -as "${OUTPUT_DIR}/${DESIGN_NAME}_placed"
