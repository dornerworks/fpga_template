if {[file isdirectory "prj"] == 1} {
  file delete -force "prj"
}

source axi_gpio.tcl

current_fileset -simset sim_1
set file_sets [list \
  "sources_1" \
  "constrs_1" \
  "sim_1" \
]
foreach x [get_filesets] {
  if {[lsearch $file_sets $x] == -1} {
    delete_fileset $x
  }
}

close_project

