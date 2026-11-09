namespace eval ::config {
#=============================================================================#
#                        Design Configuration																	#
#=============================================================================#

variable DESIGN 						chip_top	
variable CLOCK_PERIOD				5.0			;# ns
# relative to sjapr root
variable RTL_SEARCH_SUBDIRS	[ list "inputs/rtl/" ]

#=============================================================================#
#                        Environment Configuration														#
#=============================================================================#

if {![info exists ::env(SCRIPTS)]} {
	error "SCRIPTS is not set in the environment -- launch the flow with the SJapr wrapper."
}

# Set by the SJapr wrapper's -i flag: queue steps for sj_next_step
# instead of running the whole stage (see helpers/procs.tcl)
variable INTERACTIVE				[expr {[info exists ::env(SJ_INTERACTIVE)] && $::env(SJ_INTERACTIVE)}]

# Script Locations
variable SCRIPTS						[file normalize $::env(SCRIPTS)]
variable APR_SCRIPTS				${::config::SCRIPTS}/apr
variable SYNTH_SCRIPTS			${::config::SCRIPTS}/synthesis
variable HOOKS							${::config::SCRIPTS}/hooks

# Input Locations
variable DESIGN_ROOT 				[file normalize ${::config::SCRIPTS}/..]
variable RESOURCES					${::config::DESIGN_ROOT}/resources
variable INPUTS						${::config::DESIGN_ROOT}/inputs
variable RTL_SEARCH_PATHS		[ lmap d ${::config::RTL_SEARCH_SUBDIRS} { file join ${::config::DESIGN_ROOT} $d } ]

# Output Locations
variable RUNDIR							[file normalize [pwd]]
variable DBS_DIR 						$RUNDIR/DBS
variable RPT_DIR 						$RUNDIR/RPT
variable LOG_DIR 						$RUNDIR/LOG
## the following are used for grabbing relative outputs between flows;
## in general use the above
variable OUTPUT_ROOT				${::config::DESIGN_ROOT}/outputs
variable SYN_OUTPUT					${::config::OUTPUT_ROOT}/synthesis
variable APR_OUTPUT					${::config::OUTPUT_ROOT}/apr


#=============================================================================#
#	                        Synthesis Configuration														#
#=============================================================================#

# Specify enabled stages
variable LIBRARY						1
variable READ								1
variable ENVIRONMENT				1
variable CONSTRAINTS				1
variable COMPILE						1
variable DFT								0
variable REPORT							1
variable DUMP								1

# Compile: Enable/Disable DC_ULTRA option
variable WITH_DC_ULTRA   		1

#=============================================================================#
#	                           APR Configuration                              	#
#=============================================================================#

variable FLOW 							mmmc

# Specify enabled stages
variable INIT								1
variable FLOORPLAN					1
variable PLACE							1
variable CTS								1
variable ROUTE							1
variable SIGNOFF						1
}

source ${::config::SCRIPTS}/helpers/procs.tcl
