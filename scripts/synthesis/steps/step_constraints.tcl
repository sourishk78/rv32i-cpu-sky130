# TODO define a lot of the options in this file
## probably doesnt matter _that_ much, but could
## affect the number of optimization cycles 
## during sythesis
#set_max_transition
#set_max_fanout
#set_max_capacitance

# pull clock period in from config file
set CLOCK_PERIOD $::config::CLOCK_PERIOD

### Create real clock if clock port is found
##if {[sizeof_collection $::input_clocks] > 0} {
##	foreach_in_collection clk $::input_clocks {
##		set clk_name [get_attribute $clk name]
##		create_clock -name     "$clk_name"                            \
##								 -period   "$CLOCK_PERIOD"                        \
##								 -waveform "[expr $CLOCK_PERIOD/2] $CLOCK_PERIOD" \
##									$clk_name
##		# prevent buffering; step_environment.tcl also sets infinite drive on the clock ports
##		set_dont_touch_network $clk
##		set_fix_hold $clk
##
##		# input delay
##		set_input_delay -min 0.05 [all_inputs] -clock $clk_name
##		set_input_delay -max 0.3 [all_inputs] -clock $clk_name
##
##		# output delay
##		set_output_delay 0.3 [all_outputs] -clock $clk_name
##	}
##}

# ================= #
# CHIP TOP CLOCKING #
# ================= #
if {[sizeof_collection [get_ports clk_i]] > 0} {
    #set clk_name phi
    create_clock -name "coreClk" \
        -period "$CLOCK_PERIOD" \
        -waveform "[expr $CLOCK_PERIOD/2] $CLOCK_PERIOD" \
        [get_ports clk_i]
    #set_dont_touch_network find(clock, "phi")
    set_fix_hold coreClk
}
# ================= #
# ================= #
# ================= #



# Create virtual clock if clock port is not found
# (this probably wont happen)
##if {[sizeof_collection $::input_clocks] == 0} {
##  set clk_name vclk
##  create_clock -name     "vclk"                                 \
##               -period   "$CLOCK_PERIOD"                        \
##               -waveform "[expr $CLOCK_PERIOD/2] $CLOCK_PERIOD"
##  #set_dont_touch_network find(clock, "vclk")
##  set_fix_hold vclk
##}

# TODO
#set_clock_latency
#set_propagated_clock
#set_clock_uncertainty -setup 0.45 $clk_name
#set_clock_transition

# TODO not sure how delay works when we are
# generating the clock signal on chip (with RO)
# COOPER: moved into for loop
### input delay
##set_input_delay -min 0.05 [all_inputs] -clock $clk_name
##set_input_delay -max 0.3 [all_inputs] -clock $clk_name
##
### output delay
##set_output_delay 0.3 [all_outputs] -clock $clk_name

# max delay
#set_max_delay [expr 0.3*$CLOCK_PERIOD]

# min delay
#set_min_delay [expr 0.1*$CLOCK_PERIOD]

# we could optimize for area, but our utilzation is low.
# so we dont!
# (dont ask me why this is in step_constraints)
#compile -area_effort high -auto_ungroup area

# feedthrough exceptions
# we generally synthesize at the toplevel, so dont do this
#set_max_delay [expr 2.0 + $DMEM_DOUT_DLY + $DMEM_ADDR_DLY] \
#              -from       [get_ports dmem_dout]            \
#              -to         [get_ports dmem_addr]            \
#              -group_path FEEDTHROUGH

# TODO FALSE PATHS (could be implemented as hooks?)
# The following signals are internaly synchronized to
# the clk domain and can be set as false path.

#set_false_path -from dbg_uart_rxd
#set_false_path -to   dbg_uart_txd

# TODO dont touch (hooks?)
# TODO dont use (hooks?)
