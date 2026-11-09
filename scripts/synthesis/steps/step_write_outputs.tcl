# i dont know why we keep spamming this
current_design $::config::DESIGN

define_name_rules verilog -allowed "a-z0-9_" -type net
change_name -rules verilog -hierarchy

write -hierarchy -format verilog -output "$::config::RUNDIR/$::config::DESIGN.gate.v"
write -hierarchy -format ddc     -output "$::config::RUNDIR/$::config::DESIGN.ddc"

if {$::config::DFT} {
    write_test_protocol          -output "$::config::RUNDIR/$::config::DESIGN.spf"
}

write_sdc                                "$::config::RUNDIR/$::config::DESIGN.sdc"
write_sdf                                "$::config::RUNDIR/$::config::DESIGN.sdf"
write_parasitics                 -output "$::config::RUNDIR/$::config::DESIGN.spef"
