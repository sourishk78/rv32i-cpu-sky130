set_operating_conditions -analysis_type on_chip_variation \
			-max $::LIB_SS_OPCON -max_library $::LIB_SS_NAME \
			-min $::LIB_FF_OPCON -min_library $::LIB_FF_NAME

# default value. calculates all blocks with the top-level WLM
# this only matters for synthesis timing analysis
set_wire_load_mode top
# 'top' treats all nets as though they cross the entire hierarchy.
# this results in pessimistic analysis

# print inputs and outputs for logging/debug
puts "Design contains the following inputs:"
report_collection [all_inputs]
puts "Design contains the following outputs:"
report_collection [all_outputs]

set ::input_clocks [remove_from_collection [get_ports -nocase *clk*] [all_outputs]]

report_collection $::input_clocks

# set infinite drive strength on clock signals to prevent
# DC from inserting buffers on the clock tree.
# step_constraints.tcl sets dont_touch on the clock network for the same reason
if {[sizeof_collection $::input_clocks] > 0} {
  set_drive 0 $::input_clocks
}

set_driving_cell -lib_cell BUFX2 [remove_from_collection [all_inputs] $::input_clocks]

#set_load 0.5 [all_outputs] ; ## magic number (highly pessimistic?)
set_load 0.033442 [all_outputs] ;# 33.442 fF from sdc. might be wrong.
