
set MYFILE [file normalize [info script]]
set MYDIR  [file dirname ${MYFILE}]
set BASEDIR ${MYDIR}/../
set SRCDIR ${MYDIR}/../verilog/vsrc/
set TESTDIR ${MYDIR}/../verilog/vtests/ 

create_project -force vivado_project.xpr ${BASEDIR}/vivado_project -part xc7z020clg400-1

# add source files
add_files ${SRCDIR}/axis_dot_20_10.v
add_files ${SRCDIR}/dot_20_10.sv
add_files ${SRCDIR}/accel_dot.sv
add_files ${SRCDIR}/dot.sv
add_files ${SRCDIR}/axis_fmac.sv
add_files ${SRCDIR}/axis_fadd.sv

add_files ${SRCDIR}/bd_fadd/bd_fadd.bd
add_files ${SRCDIR}/bd_fmac/bd_fmac.bd
add_files ${SRCDIR}/bd_fpga/bd_fpga.bd

make_wrapper -files [get_files *.bd] -top
add_files ${SRCDIR}/bd_fadd/hdl/bd_fadd_wrapper.v
add_files ${SRCDIR}/bd_fmac/hdl/bd_fmac_wrapper.v
add_files ${SRCDIR}/bd_fpga/hdl/bd_fpga_wrapper.v

#set top
set_property top bd_fpga_wrapper [current_fileset]

# add testbenches
create_fileset -simset sim_dot
add_files -fileset sim_dot ${TESTDIR}/dot/tb_dot.sv
set_property top tb_dot [get_filesets sim_dot]

create_fileset -simset sim_dot_20_10
add_files -fileset sim_dot_20_10 ${TESTDIR}/dot_20_10/dot_20_10_tb.sv
set_property top dot_20_10_tb [get_filesets sim_dot_20_10]

# set *.sv to SystemVerilog
set_property file_type SystemVerilog [get_files *.sv]

# set active simulation
current_fileset -simset [ get_filesets sim_dot_20_10 ]

#seems to help surpress warning messages
update_compile_order -fileset sources_1
update_module_reference bd_fpga_axis_dot_20_10_0_0

#launch_runs synth_1
#wait_on_run synth_1
