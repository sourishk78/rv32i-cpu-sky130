
# Set Tie High & Low
setTieHiLoMode -reset
setTieHiLoMode \
	-cell { TIEHI TIELO } \
	-honorDontTouch false \
    -createHierPort false \
    -prefix TIEHILO_ \
    -maxDistance 2000

# Add Tie Cells
addTieHiLo -cell "TIEHI TIELO" 
