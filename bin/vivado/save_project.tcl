# -*- tab-width: 2 -*-
# Copyright (c) 2015, DornerWorks Ltd.

source $::env(NATIVE_PROJECT_ROOT)/bin/vivado/utilities.tcl

package require cmdline

set cmd_opts {
}

set cmd_help ": vivado scrip to save project and associated block diagrms"

if {[catch {array set opts [cmdline::getoptions ::argv $cmd_opts $cmd_help]}]} {
  puts [cmdline::usage $cmd_opts $cmd_help]
  return -1
}

set prj [current_project]
set lang [get_property target_language $prj]

set prj_name [get_property name $prj]
set prj_dir [get_property directory $prj]
set out_dir [file normalize "."]

set l_bd_files [list]
set l_bd_scripts [list]

# Create Tcl scripts to regenerate project BDs.
foreach bd [get_files *.bd] {
  set bd_file [file tail $bd]
  set bd_folder [file dirname $bd]/..
  set bd_name [file rootname $bd_file]
  set bd_script $out_dir/${bd_name}.tcl

  set bd_folder [relative_path_to $bd_folder $out_dir]

  open_bd_design $bd
  validate_bd_design
  write_bd_tcl -force -no_ip_version -bd_folder $bd_folder $bd_script
  close_bd_design [current_bd_design]

  lappend l_bd_files $bd
  lappend l_bd_scripts $bd_script
}

# Get a list of all non-BD related XCI files (IP).
set l_xci_files [get_files *.xci]
foreach bd [get_files *.bd] {
  set d [file normalize [file dirname $bd]]
  set l_xci_files [filter x $l_xci_files {[string first $d [file normalize $x]] != 0}]
}

set init_tcl $out_dir/${prj_name}_init.tcl
set prj_dir [relative_path_to $prj_dir $out_dir]
set prj_tcl $out_dir/${prj_name}.tcl
write_project_tcl -force -no_copy_sources -target_proj_dir $prj_dir $prj_tcl

set fd [open $init_tcl w]

# Create a temporary in-memory project to recreate BDs.
if {[llength $l_bd_scripts] > 0} {
  puts $fd "set prj \[create_project -in_memory\]"

  set part [get_property board_part $prj]
  if {[string length $part] > 0} {
    puts $fd "set_property board_part $part \$prj"
  } else {
    set part [get_property part $prj]
    if {[string length $part] > 0} {
      puts $fd "set_property part $part \$prj"
    } else {
      # ERROR
    }
  }

  puts $fd "set_property target_language $lang \$prj"

  set repo_paths [get_property ip_repo_paths $prj]
  if {[llength $repo_paths] > 0} {
    puts $fd "set_property ip_repo_paths \[list \\"
    foreach d $repo_paths {
      puts $fd "  \"[relative_path_to $d $out_dir]\" \\"
    }
    puts $fd "] \$prj"
  }

  puts $fd ""
  foreach script $l_bd_scripts {
    puts $fd "source [file tail $script]"
  }
  puts $fd ""
  puts $fd "foreach bd \[get_files *.bd\] {"
  puts $fd "  make_wrapper -top -files \$bd"
  puts $fd "}"
  puts $fd ""
  puts $fd "close_project"
  puts $fd ""
}

set rel_prj_dir [relative_path_to $prj_dir $out_dir]

# Re-generate the original project.
puts $fd "if {\[file isdirectory \"$rel_prj_dir\"\] == 1} {"
puts $fd "  file delete -force \"$rel_prj_dir\""
puts $fd "}"
puts $fd ""
puts $fd "source [file tail $prj_tcl]"
puts $fd ""

# Generate outputs for all BDs.
if {[llength $l_bd_files] > 0} {
  foreach bd $l_bd_files {
    puts $fd "generate_target all \[get_files [relative_path_to $bd $out_dir]\]"
  }
  puts $fd ""
}

# Generate outputs for all non-BD IP.
if {[llength $l_xci_files] > 0} {
  foreach x $l_xci_files {
    puts $fd "generate_target all \[get_files [relative_path_to $x $out_dir]\]"
  }
  puts $fd ""
}

puts $fd "current_fileset -simset [current_fileset -simset]"
puts $fd "set file_sets \[list \\"
foreach x [get_filesets] {
  puts $fd "  \"$x\" \\"
}
puts $fd "\]"
puts $fd "foreach x \[get_filesets\] {"
puts $fd "  if {\[lsearch \$file_sets \$x] == -1} {"
puts $fd "    delete_fileset \$x"
puts $fd "  }"
puts $fd "}"
puts $fd ""

puts $fd "close_project"
puts $fd ""

close $fd
