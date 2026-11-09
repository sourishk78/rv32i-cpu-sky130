# buffer feedthrus and tieoffs so they exist in the netlist
set_fix_multiple_port_nets -all -buffer_constants
# "multiple port" here means both ends of a net are ports rather than cells

current_design $::config::DESIGN
set_max_area  0.0 ;# dc will optimize area a whole bunch

# some compilation settings that dont apple with DC_ULTRA enabled
set_flatten false
set_structure true -timing true -boolean false


# ## CHIP TOP
# set_ungroup [get_designs pipeline_top*] true

# Compile 
if {$::config::WITH_DC_ULTRA} {
  if {$::config::DFT} {
    compile_ultra -scan -no_autoungroup -no_boundary_optimization
  } else {
    compile_ultra       -no_autoungroup -no_boundary_optimization -gate_clock
  }
  optimize_netlist -area
} else {
  if {$::config::DFT} {
    compile -scan -map_effort high -area_effort high
  } else {
    compile       -map_effort high -area_effort high
  }
}
