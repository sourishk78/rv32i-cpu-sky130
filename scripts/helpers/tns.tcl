proc get_tns {} {
    set p [report_timing -collection -max_paths 2000 -max_slack 0]
    set total 0
    foreach s [get_db $p .slack] { set total [expr {$total + $s}] }
    return $total
}