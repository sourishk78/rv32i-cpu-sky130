# Clock

#clockDesign \
#	-specFile Clock.ctstch \
#	-outDir $::config::RPT_DIR/clock_report \
#	-fixedInstBeforeCTS


set_analysis_view -setup {typical_analysis_view} -hold {typical_analysis_view}

set clockBuffers [list \
  CLKBUFX2 \
  CLKBUFX4 \
  CLKBUFX8 \
  ];

set clockInverters [list \
  CLKINVX1 \
  CLKINVX2 \
  CLKINVX4 \
  CLKINVX8 \
  ];

set clockGatingCells [list \
  ICGX1 \
  ];

set clockLogicCells [list \
  CLKAND2X2 \
  ];

set_ccopt_property target_max_trans 150ps
set_ccopt_property target_skew      150ps

set_ccopt_property buffer_cells       $clockBuffers
set_ccopt_property inverter_cells     $clockInverters
# Check the delay cell parts using doc (DEL)
#set_ccopt_property delay_cells        $clockDelayCells
set_ccopt_property clock_gating_cells $clockGatingCells

# ===== Check Design ===== #
check_design \
  -type timing \
  -out_file ${::config::RPT_DIR}/CTS/${::config::DESIGN}.check_design.timing

check_design \
  -type cts \
  -out_file ${::config::RPT_DIR}/CTS/${::config::DESIGN}.check_design.cts

check_design \
  -type opt \
  -out_file ${::config::RPT_DIR}/CTS/${::config::DESIGN}.check_design.opt

create_ccopt_clock_tree_spec
clock_opt_design -cts \
             -outDir $::config::RPT_DIR/CTS/
