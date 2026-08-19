###############################################################################
# 01_tech_setup_sky130.tcl
#
# SKY130A / Fusion Compiler
# Project : Parameterized Cache Memory Subsystem
###############################################################################

puts ""
puts "============================================================"
puts " SKY130A CACHE FLOW : 01 TECH SETUP"
puts "============================================================"

# ---------------------------------------------------------------------------
# 1. Project configuration
# ---------------------------------------------------------------------------

set SCRIPT_DIR "/home/vlsi/Documents/cache/scripts_sky130A"
set CONFIG_FILE "${SCRIPT_DIR}/design_setup_sky130.tcl"

if {![file exists $CONFIG_FILE]} {
    puts "ERROR: Cannot find:"
    puts "       $CONFIG_FILE"
    exit 1
}

source $CONFIG_FILE

# ---------------------------------------------------------------------------
# 2. Exact SKY130A paths
# ---------------------------------------------------------------------------

set SKY130A_ROOT "/home/vlsi/Documents/PDK/sky130A"

set SKY130_HD_ROOT \
    "${SKY130A_ROOT}/libs.ref/sky130_fd_sc_hd"

set SKY130_IO_ROOT \
    "${SKY130A_ROOT}/libs.ref/sky130_fd_io"

# ---------------------------------------------------------------------------
# 3. Technology LEF
# ---------------------------------------------------------------------------

set TECH_LEF \
    "${SKY130_HD_ROOT}/techlef/sky130_fd_sc_hd__nom.tlef"

set TECH_LEF_MIN \
    "${SKY130_HD_ROOT}/techlef/sky130_fd_sc_hd__min.tlef"

set TECH_LEF_MAX \
    "${SKY130_HD_ROOT}/techlef/sky130_fd_sc_hd__max.tlef"

# ---------------------------------------------------------------------------
# 4. Standard-cell physical library
# ---------------------------------------------------------------------------

set STDCELL_LEF \
    "${SKY130_HD_ROOT}/lef/sky130_fd_sc_hd.lef"

set STDCELL_GDS \
    "${SKY130_HD_ROOT}/gds/sky130_fd_sc_hd.gds"

# ---------------------------------------------------------------------------
# 5. IO physical library
# ---------------------------------------------------------------------------

set IO_LEF \
    "${SKY130_IO_ROOT}/lef/sky130_fd_io.lef"

set IO_GDS \
    "${SKY130_IO_ROOT}/gds/sky130_fd_io.gds"

# ---------------------------------------------------------------------------
# 6. SKY130 HD Liberty
# ---------------------------------------------------------------------------

set LIB_SS \
    "${SKY130_HD_ROOT}/lib/sky130_fd_sc_hd__ss_100C_1v40.lib"

set LIB_FF \
    "${SKY130_HD_ROOT}/lib/sky130_fd_sc_hd__ff_n40C_1v76.lib"

set LIB_TT \
    "${SKY130_HD_ROOT}/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# ---------------------------------------------------------------------------
# 7. Verify every required file
# ---------------------------------------------------------------------------

proc check_file {name path} {

    if {![file exists $path]} {
        puts "ERROR: Missing $name"
        puts "       $path"
        error "Required SKY130 file not found"
    }

    puts "OK: $name"
    puts "   $path"
}

puts ""
puts "------------------------------------------------------------"
puts " SKY130A FILE CHECK"
puts "------------------------------------------------------------"

check_file "Technology LEF (NOM)" $TECH_LEF
check_file "Technology LEF (MIN)" $TECH_LEF_MIN
check_file "Technology LEF (MAX)" $TECH_LEF_MAX

check_file "Standard-cell LEF" $STDCELL_LEF
check_file "Standard-cell GDS" $STDCELL_GDS

check_file "IO LEF" $IO_LEF
check_file "IO GDS" $IO_GDS

check_file "SS Liberty" $LIB_SS
check_file "FF Liberty" $LIB_FF
check_file "TT Liberty" $LIB_TT

# ---------------------------------------------------------------------------
# 8. Export lists for later scripts
# ---------------------------------------------------------------------------

set SKY130_LEF_FILES [list \
    $TECH_LEF \
    $STDCELL_LEF \
    $IO_LEF \
]

set SKY130_GDS_FILES [list \
    $STDCELL_GDS \
    $IO_GDS \
]

set SKY130_LIB_FILES [list \
    $LIB_SS \
    $LIB_FF \
    $LIB_TT \
]

# ---------------------------------------------------------------------------
# 9. Print configuration
# ---------------------------------------------------------------------------

puts ""
puts "------------------------------------------------------------"
puts " SKY130A CONFIGURATION"
puts "------------------------------------------------------------"

puts "SKY130A root : $SKY130A_ROOT"
puts "Tech LEF     : $TECH_LEF"
puts "Stdcell LEF  : $STDCELL_LEF"
puts "IO LEF       : $IO_LEF"
puts "SS Liberty   : $LIB_SS"
puts "FF Liberty   : $LIB_FF"
puts "TT Liberty   : $LIB_TT"

puts ""
puts "============================================================"
puts " 01_tech_setup_sky130.tcl COMPLETED"
puts "============================================================"