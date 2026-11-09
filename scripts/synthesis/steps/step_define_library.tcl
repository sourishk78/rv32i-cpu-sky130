# Initialize PDK locations
set ::PDK_PATH "$::config::RESOURCES/cadence_sky130"
set ::LIB_PATH "$::PDK_PATH/sky130_scl_9T_0.1.2/sky130_scl_9T/lib"
set ::LIB_DBS_PATH "$::config::RESOURCES/synopsys_libs"

# point synopsys to our pre-compiled timing libraries
set ::alib_library_analysis_path $::LIB_DBS_PATH

	# best case library
	set ::LIB_FF_NAME   "sky130_ff_1.98_0"
	set ::LIB_FF_DB 		"$::LIB_DBS_PATH/$::LIB_FF_NAME.db"

	# typical case library
	set ::LIB_TT_NAME   "sky130_tt_1.8_25";
	set ::LIB_TT_DB 		"$::LIB_DBS_PATH/$::LIB_TT_NAME.db"
	
	# worst case library
	set ::LIB_SS_NAME   "sky130_ss_1.62_125"
	set ::LIB_SS_DB 		"$::LIB_DBS_PATH/$::LIB_SS_NAME.db"

  # high speed (HS) libraries
  set ::LIB_HS_FF_DB  "$::LIB_DBS_PATH/HS_sky130_ff_1.98_0.db"
  set ::LIB_HS_TT_DB  "$::LIB_DBS_PATH/HS_sky130_tt_1.8_25.db"
  set ::LIB_HS_SS_DB  "$::LIB_DBS_PATH/HS_sky130_ss_1.62_125.db"

	# Operating Conditions (used in step_environment.tcl)
  set ::LIB_FF_OPCON  "ff_1.98_0"
  set ::LIB_TT_OPCON  "tt_1.8_25"; 
  set ::LIB_SS_OPCON  "ss_1.62_125"

  set ::LIB_WIRE_LOAD "ZeroWireload"
  set ::NAND2_NAME    "NAND2X1"

#=======#
# MACRO #
#=======#
  #==============#
  # LIBRARY PATH #
  #==============#
#  set MACRO_LIB_PATH "$::config::RESOURCES/memory"

  #================#
  # TIMING LIBRARY #
  #================#
  # 1024w, 140b
#  set sram_1024w_140b_NAME "sram_1024w_140b"
#  set sram_1024w_140b_LIB_BC_DB "${MACRO_LIB_PATH}/${sram_1024w_140b_NAME}/${sram_1024w_140b_NAME}_nldm_ff_1p10v_1p10v_0c_syn.db"
#  set sram_1024w_140b_LIB_BC_NAME "${MACRO_LIB_PATH}/${sram_1024w_140b_NAME}/${sram_1024w_140b_NAME}_nldm_ff_1p10v_1p10v_0c_syn"
#  set sram_1024w_140b_LIB_WC_DB "${MACRO_LIB_PATH}/${sram_1024w_140b_NAME}/${sram_1024w_140b_NAME}_nldm_ss_0p90v_0p90v_125c_syn.db"
#  set sram_1024w_140b_LIB_WC_NAME "${MACRO_LIB_PATH}/${sram_1024w_140b_NAME}/${sram_1024w_140b_NAME}_nldm_ss_0p90v_0p90v_125c_syn"
#  set sram_1024w_140b_LIB_NC_DB "${MACRO_LIB_PATH}/${sram_1024w_140b_NAME}/${sram_1024w_140b_NAME}_nldm_tt_1p00v_1p00v_25c_syn.db" #  set sram_1024w_140b_LIB_NC_NAME "${MACRO_LIB_PATH}/${sram_1024w_140b_NAME}/${sram_1024w_140b_NAME}_nldm_tt_1p00v_1p00v_25c_syn"

# ============ #
# OUR STUFF :) #
# ============ #
#set CF_SRAM_1024x32_tt_180V_25C_NAME "CF_SRAM"
set CF_SRAM_1024x32_tt_180V_25C_DB "${::config::DESIGN_ROOT}/inputs/CF_SRAM_1024x32/db/CF_SRAM_1024x32_tt_180V_25C.db"
set CF_SRAM_8192x32__min_tt_025C_1v80_DB "${::config::DESIGN_ROOT}/inputs/CF_SRAM_8192x32/CF_SRAM_8192x32__min_tt_025C_1v80.db"

# TODO ^^^^^ COPY IF USING NEW MACROS

  #======================#
  # OPERATING CONDITIONS #
  #======================#

  #===========#
  # WIRE LOAD #
  #===========#

  #================#
  # SYMBOL LIBRARY #
  #================#

# Search Path
set search_path ""
set search_path "${::LIB_PATH}/symbols/synopsys $search_path" ; ## mysterious and confusing
set search_path "${::LIB_PATH}/synopsys $search_path" ; ## as above

set ::target_library "$::LIB_TT_DB $::LIB_HS_TT_DB"
set ::link_library   "$::LIB_TT_DB $::LIB_SS_DB $::LIB_FF_DB $::LIB_HS_TT_DB $::LIB_HS_SS_DB $::LIB_HS_FF_DB"

# silence clock gating warnings by avoiding these cells
# TODO: revist if DFT is enabled
set_dont_use [get_lib_cells */SDFF*]

# confusing syntax.
# here,         this
# is the lib     |     for max delay (setup timing)
# and						 |												this
# is the lib     |     for min delay       |
# 							 v		 (hold timing)       v
set_min_library $::LIB_SS_DB -min_version $::LIB_FF_DB

## left as example
#=======#
# MACRO #
#=======#
  # 1024w, 140b
#  set ::link_library "$link_library $sram_1024w_140b_LIB_NC_DB"

set ::link_library "$::link_library $CF_SRAM_1024x32_tt_180V_25C_DB"
set ::link_library "$::link_library $CF_SRAM_8192x32__min_tt_025C_1v80_DB"
