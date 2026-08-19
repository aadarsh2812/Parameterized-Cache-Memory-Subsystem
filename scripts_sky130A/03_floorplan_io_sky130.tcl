###############################################################################
# 03_floorplan_io_sky130.tcl
#
# SKY130A / Fusion Compiler
#
# Physical top    : cache_io_wrapper_sky130
# Functional core : cache_top
#
# Purpose:
#   - Continue from the successfully elaborated/saved cache block
#   - Initialize the physical die/core floorplan
#   - Verify the SKY130 IO hierarchy
#   - Do NOT place the IO pads yet
#     (actual IO ring/pad placement is handled in step 04)
###############################################################################

puts ""
puts "============================================================"
puts " SKY130A CACHE FLOW : 03 FLOORPLAN / IO"
puts "============================================================"

# ---------------------------------------------------------------------------
# 1. Project paths
# ---------------------------------------------------------------------------

set PROJ_ROOT  "/home/vlsi/Documents/cache"
set OUTPUT_DIR "${PROJ_ROOT}/fc_output"

# ---------------------------------------------------------------------------
# 2. Design
# ---------------------------------------------------------------------------

set DESIGN_NAME "cache_io_wrapper_sky130"

# ---------------------------------------------------------------------------
# 3. Current design
# ---------------------------------------------------------------------------
#
# 02 has already:
#
#   - analyzed the RTL
#   - elaborated cache_io_wrapper_sky130
#   - set cache_io_wrapper_sky130 as the top
#   - saved the RTL block
#
# Therefore do NOT:
#
#   source old design_setup.tcl
#   read_lef
#   read_sdc
#   elaborate again
#
# Continue from the current FC block.
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " CURRENT DESIGN"
puts "------------------------------------------------------------"

current_design $DESIGN_NAME

puts "Current design:"
puts "  [current_design]"

# ---------------------------------------------------------------------------
# 4. Verify cache hierarchy
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " CACHE HIERARCHY"
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
# 5. Verify SKY130 IO hierarchy
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " SKY130 IO HIERARCHY"
puts "------------------------------------------------------------"

set IO_CELLS \
    [get_cells -hierarchical \
        -filter "ref_name =~ sky130_fd_io__top_*"]

puts "Detected SKY130 IO instances:"
puts "  [sizeof_collection $IO_CELLS]"

foreach_in_collection c $IO_CELLS {

    set cname [get_object_name $c]
    set rname [get_attribute $c ref_name]

    puts "  $cname -> $rname"
}

# ---------------------------------------------------------------------------
# 6. Floorplan dimensions
# ---------------------------------------------------------------------------
#
# The wrapper has 680 top-level ports and the current RTL wrapper generates
# individual SKY130 gpiov2 IO cells.
#
# A 14 mm x 14 mm initial die gives approximately 170 pad positions per
# side at an 80 um nominal gpiov2 width, which is a reasonable starting
# geometry for this very large IO count.
#
# This is an INITIAL floorplan only.
# Step 04 performs the actual IO-ring/pad arrangement.
# ---------------------------------------------------------------------------

set DIE_LL_X 0.0
set DIE_LL_Y 0.0

set DIE_UR_X 14000.0
set DIE_UR_Y 14000.0

# Core margin from die boundary

set CORE_LL_X 1000.0
set CORE_LL_Y 1000.0

set CORE_UR_X 13000.0
set CORE_UR_Y 13000.0

# ---------------------------------------------------------------------------
# 7. Print floorplan configuration
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " FLOORPLAN CONFIGURATION"
puts "------------------------------------------------------------"

puts "Die lower-left:"
puts "  ($DIE_LL_X, $DIE_LL_Y)"

puts "Die upper-right:"
puts "  ($DIE_UR_X, $DIE_UR_Y)"

puts "Core lower-left:"
puts "  ($CORE_LL_X, $CORE_LL_Y)"

puts "Core upper-right:"
puts "  ($CORE_UR_X, $CORE_UR_Y)"

# ---------------------------------------------------------------------------
# 8. Initialize floorplan
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " INITIALIZE FLOORPLAN"
puts "------------------------------------------------------------"

initialize_floorplan \
    -control_type die \
    -boundary [list \
        [list $DIE_LL_X $DIE_LL_Y] \
        [list $DIE_UR_X $DIE_UR_Y] \
    ]

puts "INFO: Die floorplan initialized."

# ---------------------------------------------------------------------------
# 9. Verify floorplan
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " FLOORPLAN CHECK"
puts "------------------------------------------------------------"

puts "Design:"
puts "  [current_design]"

puts "IO instances:"
puts "  [sizeof_collection $IO_CELLS]"

puts "cache_top instances:"
puts "  [sizeof_collection $CACHE_INSTANCES]"

# ---------------------------------------------------------------------------
# 10. Output directory
# ---------------------------------------------------------------------------

if {![file exists $OUTPUT_DIR]} {
    file mkdir $OUTPUT_DIR
}

# ---------------------------------------------------------------------------
# 11. Save floorplan block
# ---------------------------------------------------------------------------
#
# IMPORTANT:
# save_block -as accepts a block name, NOT a filesystem path.
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " SAVE FLOORPLAN BLOCK"
puts "------------------------------------------------------------"

set FLOORPLAN_BLOCK "${DESIGN_NAME}_floorplan"

puts "Saving block:"
puts "  $FLOORPLAN_BLOCK"

save_block -as $FLOORPLAN_BLOCK

# ---------------------------------------------------------------------------
# 12. Completion
# ---------------------------------------------------------------------------

puts ""
puts "============================================================"
puts " 03_floorplan_io_sky130.tcl COMPLETED"
puts "============================================================"
puts ""
puts "Design : $DESIGN_NAME"
puts "Die    : 14000 x 14000 um"
puts "Core   : 12000 x 12000 um"
puts "IO     : [sizeof_collection $IO_CELLS]"
puts "============================================================"