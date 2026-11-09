# Synopsys Verification Format (SVF) file. Logs RTL optimizations
set_svf $::config::RUNDIR/$::config::DESIGN.svf 

# set working directory. used to store intermediate (GTECH)
# representations of the RTL during elaboration
define_design_lib WORK -path $::config::RUNDIR/WORK

# dynamically generate RTL dependencies, then ingest outputs
try {
    set result [exec python3.12 $::config::SYNTH_SCRIPTS/get_rtl.py $::config::DESIGN {*}$::config::RTL_SEARCH_PATHS]
} on error {} {
    set result [exec python3 $::config::SYNTH_SCRIPTS/get_rtl.py $::config::DESIGN {*}$::config::RTL_SEARCH_PATHS]
}
set RTL_SOURCE_FILES [split [string trim [read [open $::config::SYNTH_SCRIPTS/lists/file_list.f r]]] "\n"]
set RTL_SOURCE_FILES [lsearch -all -inline -not -glob $RTL_SOURCE_FILES "*CF_SRAM*"]
set RTL_SOURCE_FILES [lsearch -all -inline -not -glob $RTL_SOURCE_FILES "*clockComplex*"]
## CHIP TOP
set_app_var search_path [concat [get_app_var search_path] \
	search_path [split [string trim [read [open $::config::SYNTH_SCRIPTS/lists/header_directory_list.f r]]] "\n"]]
set HEADER_SOURCE_FILES [split [string trim [read [open $::config::SYNTH_SCRIPTS/lists/header_list.f r]]] "\n"]

if { $HEADER_SOURCE_FILES ne "" } {
	analyze -format sverilog $HEADER_SOURCE_FILES ;# can result in double ingestion. (due to search_path) fix later 
}


# pre-compilation linting
analyze -format sverilog $RTL_SOURCE_FILES

# elaborate converts netlist to GTECH primitives
# not "compilation" yet because it still uses
# GTECH cells, not our PDK's cells
elaborate $::config::DESIGN

# check design structure after reading verilog
current_design $::config::DESIGN ;# just prints design name
# run check_design to catch bad RTL and tee it to a logfile
redirect $::config::RUNDIR/report.check {check_design} 
