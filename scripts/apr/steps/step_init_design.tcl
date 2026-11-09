# Sets up Flow Files

set ::conf_qxconf_file {NULL}
set ::conf_qxlib_file {NULL}

set ::init_qx_layermap_file "$::config::RESOURCES/cadence_sky130/sky130_release_0.1.0/libs/sky130_fd_pr_main/sky130_fd_pr_main.layermap"
set ::defHierChar {/}

set ::init_gnd_net {VSS} 
set ::init_pwr_net {VDD}

set ::init_lef_file [list \
    "$::config::RESOURCES/cadence_sky130/sky130_scl_9T_0.1.2/sky130_scl_9T_tech/lef/sky130_scl_9T.tlef" \
    "$::config::RESOURCES/cadence_sky130/sky130_scl_9T_0.1.2/sky130_scl_9T/lef/sky130_scl_9T.lef" \
    "$::config::RESOURCES/cadence_sky130/sky130_scl_9T_0.1.2/sky130_scl_9T_tech/lef/sky130_scl_9T_phyCells.lef" \
    "$::config::RESOURCES/cadence_sky130/sky130_scl_9T_0.1.2/sky130_scl_9T_HS/lef/sky130_scl_9T_HS.lef" \
    "$::config::INPUTS/CF_SRAM_1024x32/lef/CF_SRAM_1024x32.lef" \
]

# MMMC view definition -- must be registered before init_design or Innovus
# comes up physical-only and locks out all timing commands (TCLCMD-1239)
set ::init_mmmc_file "$::config::APR_SCRIPTS/steps/step_corners.tcl"

set ::init_top_cell chip_top

set ::init_verilog [list $::config::SYN_OUTPUT/$::config::DESIGN.gate.v]

set ::lsgOCPGainMult 1.000000
