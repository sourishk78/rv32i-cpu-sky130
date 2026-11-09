# Initializes Flow Settings

foreach dir [list $::config::DBS_DIR $::config::RPT_DIR $::config::LOG_DIR $::config::RPT_DIR/CTS] {
	if {![file exists $dir]} {
		file mkdir $dir
	}
}

setDistributeHost -local
setMultiCpuUsage -localCpu 8 -verbose
set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default

sj_run_step step_init_design

#setDesignMode -process 130 -topRoutingLayer 5

# sources the MMMC view file (step_corners.tcl) registered via init_mmmc_file
init_design

setAnalysisMode -analysisType onChipVariation
