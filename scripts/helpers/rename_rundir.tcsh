#!/usr/bin/env tcsh
# archive_rundir <rundir> <log_basename>
#
# If <rundir> exists, rename it to "<rundir>_<MMDD>_<HHMM>" so a fresh run can
# start from an empty directory without discarding the previous run's
# outputs. The timestamp comes from the creation time of <rundir>/<log_basename>
# (the stage's toplevel dc_shell-t/innovus log); if that file is missing, or
# the filesystem doesn't track creation time (stat reports 0), its
# modification time is used instead.

# this exists to prevent code duplication in the SJapr script; it has
# to be its own file because tcsh doesnt have functions (boooo!!!)

if ($#argv != 2) then
	echo "Usage: archive_rundir <rundir> <log_basename>"
	exit 1
endif

set rundir = "$1"
set logname = "$2"

if (! -d "$rundir") then
	exit 0
endif

set logfile = "${rundir}/${logname}"

if (-e "$logfile") then
	set src = "$logfile"
else
	set src = "$rundir"
endif

set epoch = `stat -c '%W' "$src"`
if ("$epoch" == "0") then
	set epoch = `stat -c '%Y' "$src"`
endif

set stamp = `date -d "@${epoch}" +%m%d_%H%M`

mv "$rundir" "${rundir}_${stamp}"
