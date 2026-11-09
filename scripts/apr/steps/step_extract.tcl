# ===== Extract Timing ===== #
extractRC
#rcOut \
#	-setload $::config::DBS_DIR/$::config::DESIGN.setload \
#	-rc_corner typical_rc
#rcOut \
#	-setres $::config::DBS_DIR/$::config::DESIGN.setres \
#	-rc_corner typical_rc
#rcOut \
#	-spf $::config::DBS_DIR/$::config::DESIGN.spf \
#	-rc_corner typical_rc
rcOut \
	-spef $::config::DBS_DIR/$::config::DESIGN.spef \
	-rc_corner {typical_rc}
global dbgLefDefOutVersion

# ===== Extract SDF ===== #
write_sdf \
    -recompute_delay_calc \
    -precision 4 \
    $::config::DBS_DIR/$::config::DESIGN.sdf

# ===== Save LEF ===== #
write_lef_abstract $::config::DBS_DIR/$::config::DESIGN.lef -specifyTopLayer 5 -stripePin -extractBlockPGPinLayers 5

# ===== Save DEF ===== #
set dbgLefDefOutVersion 5.7
defOut \
	-floorplan -netlist \
	-routing $::config::DBS_DIR/$::config::DESIGN.def

# ===== Save .lib ===== #
do_extract_model $::config::DBS_DIR/${::config::DESIGN}.lib -view typical_analysis_view

# ===== Save GDS  ===== #
streamOut $::config::DBS_DIR/${::config::DESIGN}.gds -mapFile $::config::RESOURCES/cadence_sky130/sky130_scl_9T_0.1.2/sky130_scl_9T/gds/sky130_stream.mapFile -libName $::config::DESIGN -units 1000 -mode ALL

streamOut $::config::DBS_DIR/${::config::DESIGN}.merged.gds -mapFile $::config::RESOURCES/cadence_sky130/sky130_scl_9T_0.1.2/sky130_scl_9T/gds/sky130_stream.mapFile -libName $::config::DESIGN -units 1000 -mode ALL \
  -merge [list $::config::INPUTS/CF_SRAM_1024x32/gds/CF_SRAM_1024x32.gds]

# ===== Save Netlist ===== #
saveNetlist $::config::DBS_DIR/${::config::DESIGN}_pnr.v -excludeLeafCell
saveNetlist $::config::DBS_DIR/${::config::DESIGN}.phy.v \
    -phys \
    -includepowerground \
    -excludeLeafCell \
    -excludeCellInst {FILL1 FILL2 FILL4 FILL8 FILL16 FILL32 FILL64 FILL_DECAP8 FILL_DECAP16}

# ===== Save the current design ===== #
saveDesign $::config::DBS_DIR/${::config::DESIGN}.enc
