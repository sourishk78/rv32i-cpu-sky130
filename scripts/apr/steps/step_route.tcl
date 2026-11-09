# ===== Detail Route ===== #
# Set NanoRoute
setNanoRouteMode -timingEngine {}
setNanoRouteMode -routeWithTimingDriven true
setNanoRouteMode -routeWithSiDriven false
#setNanoRouteMode -routeWithSiPostRouteFix false
#setNanoRouteMode -routeTopRoutingLayer 6
#setNanoRouteMode -routeBottomRoutingLayer default
#setNanoRouteMode -drouteEndIteration 5
# To remove most of the Short Edge Violations, Please use the following switch to keep all vias within the pin geometries:
setNanoRouteMode -routeWithViaInPin true
# Addition
#setNanoRouteMode -drouteAutoStop false
#setNanoRouteMode -drouteUseMultiCutViaEffort high
setNanoRouteMode -drouteFixAntenna true
#setNanoRouteMode -drouteSearchAndRepair true
#setNanoRouteMode -drouteStartIteration default
#setNanoRouteMode -drouteEndIteration 20
#setNanoRouteMode -hfrouteSearchRepair true
# For avoiding DRC error
#setNanoRouteMode -droutePostRouteSwapVia singleCut

# Route wires
routeDesign
routeDesign -wireOpt
setOptMode \
    -fixFanoutLoad true

#optDesign -postRoute -hold

# DRC fix
#ecoRoute -fix_drc

# ===== Optimize ===== #
setOptMode \
	-fixCap true \
	-fixTran true \
	-fixFanoutLoad false

optDesign -postRoute -hold
timeDesign -postRoute -hold
