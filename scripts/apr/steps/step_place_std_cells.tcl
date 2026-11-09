## Place Standard Cell

setPlaceMode -reset
setPlaceMode \
    -place_global_cong_effort auto \
    -place_global_timing_effort high \
    -place_global_clock_gate_aware true \
    -place_global_clock_power_driven false \
    -place_global_clock_power_driven_effort low \
    -place_global_ignore_scan true \
    -place_global_ignore_spare true \
    -place_global_place_io_pins false \
    -place_global_reorder_scan false \
    -place_global_module_aware_spare false \
    -place_detail_preserve_routing false \
    -place_detail_remove_affected_routing false \
    -place_detail_check_route false \
    -place_detail_swap_eeq_cells false

place_design -noPrePlaceOpt
congRepair

# Check Placements
checkPlace $::config::RPT_DIR/$::config::DESIGN.checkPlace

# TODO 2.3b
# report utilization
checkFPlan -outFile util.txt -reportUtil

