redirect -file $::config::RPT_DIR/report.timing         {check_timing}
redirect -file $::config::RPT_DIR/report.constraints    {report_constraints -all_violators -verbose}
redirect -file $::config::RPT_DIR/report.paths.max      {report_timing -path end  -delay max -max_paths 200 -nworst 2}
redirect -file $::config::RPT_DIR/report.full_paths.max {report_timing -path full -delay max -max_paths 5   -nworst 2}
redirect -file $::config::RPT_DIR/report.paths.min      {report_timing -path end  -delay min -max_paths 200 -nworst 2}
redirect -file $::config::RPT_DIR/report.full_paths.min {report_timing -path full -delay min -max_paths 5   -nworst 2}
redirect -file $::config::RPT_DIR/report.refs           {report_reference}
redirect -file $::config::RPT_DIR/report.area           {report_area}
redirect -file $::config::RPT_DIR/report.power          {report_power}

# add NAND2 size equivalent report to the area report file
# i dont honestly know why this is here
if {[info exists NAND2_NAME]} {
    set nand2_area [get_attribute [get_lib_cell $LIB_TT_NAME/$NAND2_NAME] area]
    redirect -variable area {report_area}
    regexp {Total cell area:\s+([^\n]+)\n} $area whole_match area
    set nand2_eq [expr $area/$nand2_area]
    set fp [open "$::config::RPT_DIR/report.area" a]
    puts $fp ""
    puts $fp "NAND2 equivalent cell area: $nand2_eq"
    close $fp
    puts ""
    puts "      ======================================================== "
    puts "     |                          AREA SUMMARY                  |"
    puts "     |--------------------------------------------------------|"
    puts "     |                                                        |"
    puts "     |          $NAND2_NAME cell gate area: [format {%10.4f} $nand2_area]        |"
    puts "     |                                                        |"
    puts "     |          Total Area                : [format {%10.4f} $area      ]        |"
    puts "     |          NAND2 equivalent cell area: [format {%10.4f} $nand2_eq  ]        |"
    puts "     |                                                        |"
    puts "      ======================================================== "
    puts ""
}
