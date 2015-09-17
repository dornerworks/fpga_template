# -*- tab-width: 2 -*-
# Copyright (c) 2015, DornerWorks Ltd.

#
#
#
proc launch_proj_run {run_name out_name} {
  set run [get_runs $run_name]
  set prj [current_project]

  reset_run $run_name
  launch_runs $run_name -jobs 4
  wait_on_run $run_name

  if {[get_property is_implementation $run] == 1} {
    launch_runs $run_name -to_step write_bitstream
    wait_on_run $run_name
  }

  set prj_dir [get_property directory $prj]
  set run_dir [get_property directory $run]
  set out_dir [file normalize $prj_dir/../out/${out_name}]

  file mkdir $out_dir

  catch {file copy -force {*}[glob -nocomplain $run_dir/*.rpt] $out_dir }
  catch {file copy -force {*}[glob -nocomplain $run_dir/*.dcp] $out_dir }
  catch {file copy -force {*}[glob -nocomplain $run_dir/*.log] $out_dir }

  if {[get_property is_implementation $run] == 1} {
    catch {file copy -force {*}[glob -nocomplain $run_dir/*.bit] $out_dir }
    catch {file copy -force {*}[glob -nocomplain $run_dir/*.mmi] $out_dir }
    catch {file copy -force {*}[glob -nocomplain $run_dir/*.hwdef] $out_dir }
    catch {file copy -force {*}[glob -nocomplain $run_dir/*.sysdef] $out_dir }
  }
}

#
#
#
proc filter {fvar flist fexpr} {
  upvar 1 $fvar var
  set result {}
  foreach var $flist {
    set temp $var
    if {[uplevel 1 [list expr $fexpr]]} {
      lappend result $temp
    }
  }
  return $result
}

#
#
#
proc relative_path_to { to_path {from_path "."} } {
  if {[file isfile from_path] || ![file isdirectory $from_path]} {
    set from_path [file dirname $from_path]
  }

  set cwd [file normalize [pwd]]

  if {[file pathtype $to_path] eq "relative"} {
    if {[string equal $from_path $cwd]} {
      return $to_path
    }
    set to_path [file join $cwd $to_path]
  }

  if {[file pathtype $from_path] eq "relative"} {
    set from_path [file join $cwd $from_path]
  }

  set l_to_path [file split [file normalize $to_path]]
  set l_from_path [file split [file normalize $from_path]]

  if {[lindex $l_to_path 0] != [lindex $l_from_path 0]} {
    return $to_path
  }

  set idx 1
  set to_len [llength $l_to_path]
  set from_len [llength $l_from_path]

  while {($idx < $to_len) && ($idx < $from_len)} {
    if {[lindex $l_to_path $idx] != [lindex $l_from_path $idx]} {
      break;
    }
    incr idx
  }

  set up_idx $idx
  set up_path ""

  while {$up_idx < $from_len} {
    set up_path [file join ".." $up_path]
    incr up_idx
  }

  return [file join $up_path {*}[lrange $l_to_path $idx $to_len]]
}
