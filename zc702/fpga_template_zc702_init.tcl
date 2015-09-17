set prj [create_project -in_memory]
set_property board_part em.avnet.com:microzed_7020:part0:1.0 $prj
set_property target_language VHDL $prj

source fpga_template_zc702_bd.tcl

foreach bd [get_files *.bd] {
  make_wrapper -top -files $bd
}

close_project

if {[file isdirectory "prj"] == 1} {
  file delete -force "prj"
}

source fpga_template_zc702.tcl

generate_target all [get_files bd/fpga_template_zc702_bd/fpga_template_zc702_bd.bd]

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

