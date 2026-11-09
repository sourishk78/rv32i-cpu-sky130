# Set Optimization
setOptMode \
	-effort high \
	-leakagePowerEffort none \
	-dynamicPowerEffort none \
	-reclaimArea true \
	-simplifyNetlist false \
	-allEndPoints false \
	-setupTargetSlack 0 \
	-holdTargetSlack 0 \
	-maxDensity 0.95 \
	-drcMargin 0 \
	-usefulSkew false \
    -addPortAsNeeded false 

# Timing Analysis Options 
# #--- Note: (IMPOPT-6080) AAE-SI Optimization can only be turned on when the timing analysis mode is set to OCV.
#setDelayCalMode -engine aae -SIAware true -reportOutBound true
#setAnalysisMode -analysisType onChipVariation -cppr both
#setExtractRCMode -engine preRoute
#extractRC

# Optimize
setOptMode \
	-fixCap true \
	-fixTran true \
	-fixFanoutLoad false
optDesign -preCTS -outDir $::config::RPT_DIR/timingReports
