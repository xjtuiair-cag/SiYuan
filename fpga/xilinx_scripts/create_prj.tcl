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

source ../xilinx_scripts/add_sources.tcl

if {$::env(BOARD) eq "genesys2"} {
    set_property top sy_soc_genesys2 [current_fileset]   
} elseif {$::env(BOARD) eq "vc707"} {
    set_property top sy_soc_vc707 [current_fileset]   
} else {
    exit 1
}

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

# add_files -fileset constrs_1 -norecurse ../constraints/$project.xdc