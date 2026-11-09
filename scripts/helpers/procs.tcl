####################################################
# Helper procs for running the flow								 #
# Cooper Shaw, 7/24/26														 #
####################################################


# Interactive-mode state: while a driver is sourced with
# $::config::INTERACTIVE set, sj_run_step collects step names here
# instead of executing them (see sj_next_step and friends below)
namespace eval ::sj {
	variable step_queue {}
	variable collecting $::config::INTERACTIVE
}

# Source a path, forwarding output to logfile
proc sj_source_logged {script_path logfile} {
	set cmd [list source $script_path]
	uplevel 1 [list redirect -tee $logfile $cmd]
}

# Log per-step status and duration
proc sj_log_summary {step_name status seconds} {
	set fh [open $::config::LOG_DIR/flow_summary.log a]
	puts $fh [format "%-28s %-6s %5ds" $step_name $status $seconds]
	close $fh
}

# Check for a hook file and run it if found
# A design-specific hook (<step_name>.<DESIGN>.<type>.tcl) takes precedence
# over the general one (<step_name>.<type>.tcl)
proc sj_run_hook {step_name type} {
	set hookfile ""
	foreach candidate [list $step_name.$::config::DESIGN.$type.tcl $step_name.$type.tcl] {
		if {[file exists $::config::HOOKS/$candidate]} {
			set hookfile $candidate
			break
		}
	}
	if {$hookfile eq ""} {
		return
	}

	set hookpath $::config::HOOKS/$hookfile
	set hookname [file rootname $hookfile]
	set logfile $::config::LOG_DIR/$hookname.log
	puts "HOOK_LOCATED: $hookfile"

	set start [clock seconds]
	puts "SCRIPT_START [clock format $start -format %H:%M:%S]: $hookpath"
	puts "             log -> $logfile"

	set rc [catch {sj_source_logged $hookpath $logfile} err]

	set elapsed [expr {[clock seconds] - $start}]
	set stamp [clock format [clock seconds] -format %H:%M:%S]
	if {$rc} {
		puts "SCRIPT_FAIL  $stamp (${elapsed}s): $hookfile"
		puts "  -> see $logfile"
		puts "  -> $err"
		sj_log_summary $hookname FAIL $elapsed
		return -code error -errorinfo $::errorInfo $err
	}
	puts "SCRIPT_END   $stamp (${elapsed}s): $hookpath"
	sj_log_summary $hookname OK $elapsed
}

# Run a step, teeing log and checking for hooks
proc sj_exec_step {step_name} {
	set matches [split [string trim [exec find $::config::SCRIPTS -name $step_name.tcl]] \n]

	if {[llength $matches] == 0 || [lindex $matches 0] eq ""} {
		puts "ERROR: No file matching $step_name.tcl was found in the scripts directory."
		return
	}
	if {[llength $matches] > 1} {
		puts "ERROR: $step_name.tcl is ambiguous -- step file basenames must be unique:"
		foreach m $matches { puts "  $m" }
		return -code error "ambiguous step name: $step_name"
	}

	set script_path [lindex $matches 0]
	set logfile $::config::LOG_DIR/$step_name.log

	sj_run_hook $step_name pre

	set start [clock seconds]
	puts "SCRIPT_START [clock format $start -format %H:%M:%S]: $script_path"
	puts "             log -> $logfile"

	set rc [catch {sj_source_logged $script_path $logfile} err]

	set elapsed [expr {[clock seconds] - $start}]
	set stamp [clock format [clock seconds] -format %H:%M:%S]
	if {$rc} {
		puts "SCRIPT_FAIL  $stamp (${elapsed}s): $step_name"
		puts "  -> see $logfile"
		puts "  -> $err"
		sj_log_summary $step_name FAIL $elapsed
		return -code error -errorinfo $::errorInfo $err
	}
	puts "SCRIPT_END   $stamp (${elapsed}s): $script_path"
	sj_log_summary $step_name OK $elapsed

	sj_run_hook $step_name post
}

# Run a step -- or, while an interactive driver is collecting its step
# list, queue it for sj_next_step instead
proc sj_run_step {step_name} {
	if {$::sj::collecting} {
		lappend ::sj::step_queue $step_name
		puts "QUEUED: $step_name"
		return
	}
	sj_exec_step $step_name
}

# End interactive step collection: called by the drivers once all steps
# are queued, so later sj_run_step calls execute immediately again
proc sj_end_collection {} {
	set ::sj::collecting 0
	puts ""
	puts "Interactive mode: [llength $::sj::step_queue] steps queued."
	sj_list_steps
	puts "Commands: sj_next_step | sj_run_remaining | sj_skip_step | sj_list_steps"
}

# Show the remaining step queue, next step first
proc sj_list_steps {} {
	if {[llength $::sj::step_queue] == 0} {
		puts "No steps remaining."
		return
	}
	set first 1
	foreach step $::sj::step_queue {
		if {$first} {
			puts "  -> $step"
			set first 0
		} else {
			puts "     $step"
		}
	}
}

# Run the next queued step; on failure it stays at the head of the
# queue so it can be retried (or dropped with sj_skip_step)
proc sj_next_step {} {
	if {[llength $::sj::step_queue] == 0} {
		puts "No steps remaining."
		return 0
	}
	set step_name [lindex $::sj::step_queue 0]
	if {[catch {sj_exec_step $step_name} err]} {
		puts "sj_next_step: $step_name failed and remains next in the queue."
		return 0
	}
	set ::sj::step_queue [lrange $::sj::step_queue 1 end]
	if {[llength $::sj::step_queue]} {
		puts "NEXT STEP: [lindex $::sj::step_queue 0]"
	} else {
		puts "All steps complete."
	}
	return 1
}

# Drop the next queued step without running it
proc sj_skip_step {} {
	if {[llength $::sj::step_queue] == 0} {
		puts "No steps remaining."
		return
	}
	set step_name [lindex $::sj::step_queue 0]
	set ::sj::step_queue [lrange $::sj::step_queue 1 end]
	puts "SKIPPED: $step_name"
	sj_list_steps
}

# Run all remaining queued steps, stopping at the first failure
proc sj_run_remaining {} {
	while {[llength $::sj::step_queue]} {
		if {![sj_next_step]} {
			return
		}
	}
}
