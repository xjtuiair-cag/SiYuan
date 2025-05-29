# Copyright 2018 ETH Zurich and University of Bologna.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Author: Florian Zaruba <zarubaf@iis.ee.ethz.ch>

if {$::env(BOARD) eq "genesys2"} {
    add_files -fileset constrs_1 -norecurse ../xilinx_constraint/genesys2.xdc
} elseif {$::env(BOARD) eq "vc707"} {
    add_files -fileset constrs_1 -norecurse ../xilinx_constraint/vc707.xdc
} else {
    exit 1
}

read_ip ../xilinx_ip/xlnx_mig_7_ddr3/ip/xlnx_mig_7_ddr3.xci
read_ip ../xilinx_ip/xlnx_axi_clock_converter/ip/xlnx_axi_clock_converter.xci
read_ip ../xilinx_ip/xlnx_axi_dwidth_converter/ip/xlnx_axi_dwidth_converter.xci
read_ip ../xilinx_ip/xlnx_axi_gpio/ip/xlnx_axi_gpio.xci
read_ip ../xilinx_ip/xlnx_axi_quad_spi/ip/xlnx_axi_quad_spi.xci
read_ip ../xilinx_ip/xlnx_clk_gen/ip/xlnx_clk_gen.xci
read_ip ../xilinx_ip/div64x64_d20_s/ip/div64x64_d20_s.xci
read_ip ../xilinx_ip/div64x64_d20_us/ip/div64x64_d20_us.xci
read_ip ../xilinx_ip/sdp_512x64sd1/ip/sdp_512x64sd1.xci
# read_ip ../xilinx_ip/fifo_64to32/ip/fifo_64to32.xci
# read_ip ../xilinx_ip/fifo_cmd_1/ip/fifo_cmd_1.xci
# read_ip ../xilinx_ip/fifo_data/ip/fifo_data.xci
# read_ip ../xilinx_ip/mpu_mac_1x_accumulator/ip/mpu_mac_1x_accumulator.xci
# read_ip ../xilinx_ip/pal_reoder_buffer/ip/pal_reoder_buffer.xci
# read_ip ../xilinx_ip/sdp_w512x64_r512x64/ip/sdp_w512x64_r512x64.xci
# read_ip ../xilinx_ip/vputy_mul_8_8_clk1x/ip/vputy_mul_8_8_clk1x.xci
# read_ip ../xilinx_ip/wcmd2axi_asyn_fifo/ip/wcmd2axi_asyn_fifo.xci
# read_ip ../xilinx_ip/wdata2axi_asyn_fifo/ip/wdata2axi_asyn_fifo.xci
# read_ip ../xilinx_ip/xbip_dsp48_macro_0/ip/xbip_dsp48_macro_0.xci
# read_ip ../xilinx_ip/xbip_dsp48_macro_1/ip/xbip_dsp48_macro_1.xci
# read_ip ../xilinx_ip/xbip_dsp48_no_pcin/ip/xbip_dsp48_no_pcin.xci

source ../xilinx_scripts/add_sources.tcl

set_property top sy_soc_fpga [current_fileset]

#########
# vc707 #
#########

if {$::env(BOARD) eq "vc707"} {
    read_verilog -sv {../../de/inc/vc707.svh ../../de/inc/registers.svh ../../de/inc/glb_def.svh ../../de/inc/sy_cache.svh  
    ../../de/inc/sy_mmu.svh ../../de/inc/sy_ovall.svh ../../de/inc/sy_ppl.svh}
    set file "vc707.svh"
    set registers "registers.svh"
} elseif {$::env(BOARD) eq "genesys2"} {
    read_verilog -sv {../../de/inc/genesys2.svh ../../de/inc/registers.svh ../../de/inc/glb_def.svh ../../de/inc/sy_cache.svh  
    ../../de/inc/sy_mmu.svh ../../de/inc/sy_ovall.svh ../../de/inc/sy_ppl.svh}
    set file "genesys2.svh"
    set registers "registers.svh"
} else {
    exit 1
}

set file_obj [get_files -of_objects [get_filesets sources_1] [list "*$file" "*$registers"]]
set_property -dict { file_type {Verilog Header} is_global_include 1} -objects $file_obj

update_compile_order -fileset sources_1

synth_design -rtl -name rtl_1

set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]

launch_runs synth_1
wait_on_run synth_1
open_run synth_1

exec mkdir -p reports/
exec rm -rf reports/*

check_timing -verbose                                                   -file reports/$project.check_timing.rpt
report_timing -max_paths 100 -nworst 100 -delay_type max -sort_by slack -file reports/$project.timing_WORST_100.rpt
report_timing -nworst 1 -delay_type max -sort_by group                  -file reports/$project.timing.rpt
report_utilization -hierarchical                                        -file reports/$project.utilization.rpt
report_cdc                                                              -file reports/$project.cdc.rpt
report_clock_interaction                                                -file reports/$project.clock_interaction.rpt

# set for RuntimeOptimized implementation
set_property "steps.place_design.args.directive" "RuntimeOptimized" [get_runs impl_1]
set_property "steps.route_design.args.directive" "RuntimeOptimized" [get_runs impl_1]

launch_runs impl_1
wait_on_run impl_1
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
open_run impl_1

# output Verilog netlist + SDC for timing simulation
write_verilog -force -mode funcsim ${project}_funcsim.v
write_verilog -force -mode timesim ${project}_timesim.v
write_sdf     -force ${project}_timesim.sdf

# reports
exec mkdir -p reports/
exec rm -rf reports/*
check_timing                                                              -file reports/${project}.check_timing.rpt
report_timing -max_paths 100 -nworst 100 -delay_type max -sort_by slack   -file reports/${project}.timing_WORST_100.rpt
report_timing -nworst 1 -delay_type max -sort_by group                    -file reports/${project}.timing.rpt
report_utilization -hierarchical                                          -file reports/${project}.utilization.rpt
