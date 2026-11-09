# ===== Floorplan ===== #

## Chip Dimension
### TODO adjust to more appropriate values
### heads up: these variables aren't magic!
### make sure you pass them to the appropriate command.
set x_dim 1000.642
set y_dim 500.321

## Core Offsets
### Sets an offset on where standard cells can be placed.
### This prevents the tools from placing cells under
### the design's power rings on the edges of the floorplan
set left_offset     9.6
set right_offset    9.6
set top_offset      9.6
set bottom_offset   9.6

# FloorPlan Cmd.
#floorPlan -site CoreSite \
# -s $x_dim $y_dim \ 
# $left_offset $right_offset $bottom_offset $top_offset
## TODO is this using the right variables?
floorPlan -site CoreSite -adjustToSite \
	-s $x_dim $y_dim \
	$left_offset $bottom_offset $right_offset $top_offset

# Set Design Mode
setDesignMode -process 130 -topRoutingLayer 5

### ===== Place Blocks ===== #
# Edit halo around every block
## TODO are the values for these macro names right?
## reference chip_top.sv
set macro_name_1 data_memory/u_sram
set macro_name_2 instruction_memory/u_sram

## TODO place blocks in an appropriate location (not 0,0!)
placeInstance $macro_name_1 122.051 106.373 -fixed
placeInstance $macro_name_2 509.921 106.373 -fixed

# add block halos
addHaloToBlock {21 21 21 21} $macro_name_1
addHaloToBlock {21 21 21 21} $macro_name_2

# ===== Power Plan ===== #
# ===== Define Global Nets ===== # 
globalNetConnect VDD \
	-type pgpin \
	-pin VDD \
	-inst *
globalNetConnect VSS \
	-type pgpin \
	-pin VSS \
	-inst *
globalNetConnect VDD \
	-type tiehi \
	-all \
  -override \
  -verbose
globalNetConnect VSS \
	-type tielo \
	-all \
  -override \
  -verbose

# SRAM GNC Rules
  globalNetConnect VSS \
	-type pgpin \
	-pin vgnd \
	-inst *
  globalNetConnect VSS \
	-type pgpin \
	-pin vnb \
	-inst *

  globalNetConnect VDD \
	-type pgpin \
	-pin vpwrm \
	-inst *
  globalNetConnect VDD \
	-type pgpin \
	-pin vpwrp \
	-inst *
  globalNetConnect VDD \
	-type pgpin \
	-pin vpwra \
	-inst *
  globalNetConnect VDD \
	-type pgpin \
	-pin vpb \
	-inst *

# ===== Pre Process ===== # 
set sprCreateIeRingNets {}
set sprCreateIeRingLayers {}
set sprCreateIeRingWidth 1.0
set sprCreateIeRingSpacing 1.0
set sprCreateIeRingOffset 1.0
set sprCreateIeRingThreshold 1.0
set sprCreateIeRingJogDistance 1.0

# ===== Core Power Ring=====  #
setAddRingMode -stacked_via_top_layer met5
setAddRingMode -stacked_via_bottom_layer met1

#copy example. vssd1 on outside, vccd1 on inside
addRing \
	-center 1 \
	-type core_rings -follow io \
	-jog_distance 0.4 \
	-threshold 0.4 \
	-nets {VSS VDD} \
	-layer {bottom met5 top met5 right met4 left met4} \
	-width 6.4 \
	-spacing 3.2 \
	-offset 0

# ===== Block Power Ring=====  #

## TODO refer to part 2.3b
createInstGroup group_SRAMs
addInstToInstGroup group_SRAMs $macro_name_1
addInstToInstGroup group_SRAMs $macro_name_2
selectInst $macro_name_1
selectInst $macro_name_2

## TODO part 2.3c
addRing \
	-around cluster \
	-jog_distance 0.4 \
	-nets {VDD VSS} \
	-type block_rings \
	-layer {bottom met5 top met5 right met4 left met4} \
	-width 6.2 \
	-spacing 3.2 \
	-offset 5
## ^^ more flags here


## deselect macro groups
deselectAll

# ===== Route Power Wires =====  #
sroute \
  -connect { floatingStripe padPin padRing corePin  } \
	-layerChangeRange { met1 met5 } \
	-padPinPortConnect { allPort oneGeom } \
	-stripeSCpinTarget { stripe blockring padring ring ringpin blockpin } \
	-blockPin useLef \
	-allowJogging 1 \
	-crossoverViaLayerRange { met1 met5 } \
	-allowLayerChange 1 \
	-targetViaLayerRange { met1 met5 } \
	-nets { VDD VSS }

sroute -connect { blockPin } \
       -layerChangeRange { met3 met5 } \
       -nets { VDD VSS } \
       -blockPinTarget { nearestRingStripe nearestTarget } \
       -allowLayerChange 1 \
       -blockPinLayer { met3 }


# ===== Power Grid =====  #
setAddStripeMode \
 -stacked_via_top_layer met5 \
 -stacked_via_bottom_layer met1 \
 -allow_jog {padcore_ring block_ring}
 #-break_at {block_ring}

set minDis 16

set M2_Width 2
set M2_Offset [expr {$M2_Width/-2}]
set M2_Dis [expr {4*$minDis}]
set M2_Spacing [expr {$M2_Dis/2-$M2_Width}]
set M3_Width 2
set M3_Offset [expr {$M3_Width/-2}]
set M3_Dis [expr {4*$minDis}]
set M3_Spacing [expr {$M3_Dis/2-$M3_Width}]
#
### Many of these numbers are pulled directly
### From the openframe example project
set M4_Width 6.4
set M4_Offset [expr {$M4_Width/-2}]
set M4_Dis 40
set M4_Spacing 3.2

set M5_Width 6.4
set M5_Offset [expr {$M5_Width/-2}]
set M5_Dis 40
set M5_Spacing 3.2


addStripe \
	-nets {VDD VSS} \
	-layer met4 \
	-direction vertical \
	-width 6.4 \
	-spacing 3.2 \
	-set_to_set_distance 40 \
	-xleft_offset $M4_Offset \
	-switch_layer_over_obs false \
	-max_same_layer_jog_length 2 \
	-padcore_ring_top_layer_limit met5 \
	-padcore_ring_bottom_layer_limit met1 \
	-block_ring_top_layer_limit met5 \
	-block_ring_bottom_layer_limit met1 \
	-use_wire_group 0 \
	-snap_wire_center_to_grid None

# Layer M5
setAddStripeMode \
 -stacked_via_top_layer met5 \
 -stacked_via_bottom_layer met1 \
 -allow_jog none 
 #-break_at {block_ring}
addStripe \
	-nets {VDD VSS} \
	-layer met5 \
	-direction horizontal \
	-width 6.4 \
	-spacing 3.2 \
	-set_to_set_distance 40 \
	-ybottom_offset $M5_Offset \
	-merge_stripes_value $M5_Width \
	-max_same_layer_jog_length 6 \
	-padcore_ring_top_layer_limit met5 \
	-padcore_ring_bottom_layer_limit met4 \
	-block_ring_top_layer_limit met5 \
	-block_ring_bottom_layer_limit met4
	#-extend_to design_boundary \
# Remove routing blockage
##deleteRouteBlk -all

# ===== Spread Pins ===== #
# moved to the end of the file to avoid conflicting with power stripes
set pins_to_spread_in [dbget [dbget top.terms.isOutput 0 -p].name] 
set pins_to_spread_out [dbget [dbget top.terms.isOutput 1 -p].name] 

#input pins

editPin -spreadType SIDE -side RIGHT \
    -layerH met4 -layerV met3 \
    -pin $pins_to_spread_out -fixOverlap 1

editPin -spreadType SIDE -side LEFT \
    -layerH met4 -layerV met3 \
    -pin $pins_to_spread_in -fixOverlap 1
