###############################################################################
# 09_route_sky130.tcl
###############################################################################
source "/home/vlsi/Documents/cache/scripts/design_setup_sky130.tcl"
current_design $DESIGN_NAME
read_sdc $SDC_FILE

set_ignored_layers -min_routing_layer $MIN_ROUTING_LAYER \
                   -max_routing_layer $MAX_ROUTING_LAYER

route_auto

report_route_status > "${REPORT_DIR}/09_route_status.rpt"
report_timing -delay_type max -max_paths 20 > "${REPORT_DIR}/09_postroute_setup.rpt"
report_timing -delay_type min -max_paths 20 > "${REPORT_DIR}/09_postroute_hold.rpt"

save_block -as "${OUTPUT_DIR}/${DESIGN_NAME}_routed"
