# ===== Verify the Geometry ===== #

setVerifyGeometryMode \
	-area { 0 0 0 0 } \
	-minWidth true \
	-minSpacing true \
	-minArea true \
	-sameNet true \
	-short true \
	-overlap true \
	-offRGrid false \
	-offMGrid true \
	-mergedMGridCheck true \
	-minHole true \
	-implantCheck true \
	-minimumCut true \
	-minStep true \
	-viaEnclosure true \
	-antenna false \
	-insuffMetalOverlap true \
	-pinInBlkg false \
	-diffCellViol true \
	-sameCellViol false \
	-padFillerCellsOverlap true \
	-routingBlkgPinOverlap true \
	-routingCellBlkgOverlap true \
	-regRoutingOnly false \
	-stackedViasOnRegNet false \
	-wireExt true \
	-useNonDefaultSpacing false \
	-maxWidth true \
	-maxNonPrefLength -1 \
	-error 10000 \
	-warning 500
verifyGeometry \
  -report $::config::RPT_DIR/$::config::DESIGN.geom.rpt
# ===== Verify Connectivity ===== #
verifyConnectivity \
	-type all \
	-error 10000 \
	-warning 500 \
  -report $::config::RPT_DIR/$::config::DESIGN.conn.rpt
