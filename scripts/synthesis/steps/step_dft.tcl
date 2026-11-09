# TODO im ignoring this file for now
# DFT Signal Type Definitions
set_dft_signal -view spec         -type ScanEnable  -port scan_enable -active_state 1
set_dft_signal -view existing_dft -type ScanEnable  -port scan_enable -active_state 1
set_dft_signal -view spec         -type Constant    -port scan_mode   -active_state 1
set_dft_signal -view existing_dft -type Constant    -port scan_mode   -active_state 1
set_dft_signal -view existing_dft -type ScanClock   -port dco_clk     -timing [list 45 55]
set_dft_signal -view existing_dft -type ScanClock   -port lfxt_clk    -timing [list 45 55]
set_dft_signal -view existing_dft -type Reset       -port reset_n     -active 0

# DFT Configuration
set_dft_insertion_configuration -preserve_design_name true
set_scan_configuration -style multiplexed_flip_flop
set_scan_configuration -clock_mixing mix_clocks
set_scan_configuration -chain_count 3

# DFT Test Protocol Creation
create_test_protocol

# DFT Design Rule Check
redirect -tee -file $::config::RUNDIR/report.dft_drc           {dft_drc}
redirect      -file $::config::RUNDIR/report.dft_drc_verbose   {dft_drc -verbose}
redirect      -file $::config::RUNDIR/report.dft_drc_coverage  {dft_drc -coverage_estimate}
redirect      -file $::config::RUNDIR/report.dft_scan_config   {report_scan_configuration}
redirect      -file $::config::RUNDIR/report.dft_insert_config {report_dft_insertion_configuration}

# Preview DFT insertion
redirect -tee -file $::config::RUNDIR/report.dft_preview       {preview_dft}
redirect      -file $::config::RUNDIR/report.dft_preview_all   {preview_dft -show all -test_points all}

# DFT insertion
insert_dft

# DFT Incremental Compile
if {$::config::WITH_DC_ULTRA} {
  compile_ultra -scan -incremental
} else {
  compile       -scan -incremental
}

# DFT Coverage estimate
redirect      -file $::config::RUNDIR/report.dft_drc_coverage_post_insert {dft_drc -coverage_estimate}
