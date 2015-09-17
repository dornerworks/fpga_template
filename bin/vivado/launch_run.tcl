# -*- tab-width: 2 -*-
# Copyright (c) 2015, DornerWorks Ltd.

package require cmdline

set cmd_opts {
  { out_dir.arg    "" "output directory" }
  { sdk_dir.arg    "" "SDK output directory" }
  { script_dir.arg "" "directory with run scripts" }
  { jobs.arg        4 "number of parallel jobs to use" }
  { netlist           "generate a gate level timing netlist, default=off"}
  { debug             "turn on debugging, default=off" }
}

set cmd_help ": vivado script to launch runs"

if {[catch {array set opts [cmdline::getoptions ::argv $cmd_opts $cmd_help]}]} {
  puts [cmdline::usage $cmd_opts $cmd_help]
  return -1
}

if {[catch {set prj [current_project]}]} {
  puts "no project is currently open"
  return -1
}

if {[llength $::argv] != 1} {
  puts "no run name specified"
  return -1
}

set prj_dir [get_property directory $prj]

set run_name [lindex $::argv 0]
if {[llength $opts(script_dir)] > 0} {
  set script_dir $opts(script_dir)
} else {
  set script_dir $prj_dir/../bin
}

set run_script [file normalize ${run_name}]
if {[file isfile $run_script] == 1} {
  return [source $run_script]
}
set run_script [file normalize ${script_dir}/run_${run_name}.tcl]
if {[file isfile $run_script] == 1} {
  return [source $run_script]
}

set script [file normalize ${script_dir}/run_pre_hook.tcl]
if {[file isfile $script] == 1} {
  source $script
}
set script [file normalize ${script_dir}/run_${run_name}_pre_hook.tcl]
if {[file isfile $script] == 1} {
  source $script
}

set run [get_runs $run_name]
if {[get_property is_implementation $run] == 1} {
  launch_runs $run_name -to_step write_bitstream
  wait_on_run $run_name
}

set run_dir [get_property directory $run]
if {[llength $opts(out_dir)] > 0} {
  set out_dir [file normalize $opts(out_dir)]
} else {
  set out_dir [file normalize $prj_dir/../out/$run_name]
}
if {[llength $opts(sdk_dir)] > 0} {
  set sdk_dir [file normalize $opts(sdk_dir)]
} else {
  set sdk_dir $out_dir
}

if {[file isdirectory $out_dir] == 1} {
  file delete -force $out_dir
}

file mkdir $out_dir

reset_run $run_name
launch_runs $run_name -jobs $opts(jobs)
wait_on_run $run_name

catch {file copy -force {*}[glob -nocomplain $run_dir/*.rpt] $out_dir}
catch {file copy -force {*}[glob -nocomplain $run_dir/*.dcp] $out_dir}
catch {file copy -force {*}[glob -nocomplain $run_dir/*.log] $out_dir}

if {[get_property is_synthesis $run] == 1} {
  catch {file copy -force $run_dir/synth_timestamp.txt $out_dir}
}

if {[get_property is_implementation $run] == 1} {
  set synth_dir [get_property directory [get_property parent $run]]

  catch {file copy -force $synth_dir/synth_timestamp.txt $out_dir}
  catch {file copy -force $run_dir/impl_timestamp.txt $out_dir}
  
  catch {file copy -force {*}[glob -nocomplain $run_dir/*.bit] $out_dir}
  catch {file copy -force {*}[glob -nocomplain $run_dir/*.mmi] $out_dir}
  catch {file copy -force {*}[glob -nocomplain $run_dir/*.hwdef] $sdk_dir}
  catch {file copy -force {*}[glob -nocomplain $run_dir/*.sysdef] $sdk_dir}

  if {$opts(netlist) == 1} {
    set dcp [glob -nocomplain $out_dir/*_routed.dcp]
    if {[llength $dcp] > 0} {
      if {[llength $dcp] == 1} {
        set name [file rootname [file tail $dcp]]

        open_run $run
        write_verilog -mode timesim -sdf_anno true $out_dir/${name}.v
        write_sdf -process_corner fast $out_dir/${name}_fast.sdf
        write_sdf -process_corner slow $out_dir/${name}_slow.sdf

        close_design
      }
    }
  }
}

set script [file normalize ${script_dir}/run_${run_name}_post_hook.tcl]
if {[file isfile $script]} {
  source $script
}

set script [file normalize ${script_dir}/run_post_hook.tcl]
if {[file isfile $script]} {
  source $script
}
