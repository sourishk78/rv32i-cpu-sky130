setOptMode \
	-fixCap true \
	-fixTran true \
	-fixFanoutLoad false
optDesign -postCTS -hold -outDir $::config::RPT_DIR/timingReports

timeDesign -postCTS
timeDesign -postCTS -hold

saveDesign $::config::DESIGN.postCts.dat