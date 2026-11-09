# ===== Add Filler Cells ===== #
setFillerMode -reset
setFillerMode \
	-core { FILL1 FILL2 FILL4 FILL8 \
            FILL_DECAP8 } \
	-createRows true \
	-doDRC true \
	-ecoMode false

# ===== Add Filler Cells ===== #
addFiller -prefix FILL
