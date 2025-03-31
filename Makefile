# Author: shenghuan liu
# Date: 2025/01/08
# Description: Makefile for SiYuan.
# root path
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
root-dir := $(dir $(mkfile_path))
BOARD = vc707
DE_HOME = $(root-dir)/de
CONFIG := base.yaml
CONFIG_FILE = $(addprefix $(root-dir)/config/, $(CONFIG))
SCRIPTS_DIR = $(root-dir)/config/scripts
DTS_OUT_PATH = $(root-dir)/de/ip/bootrom_fpga/sy.dts
SOC_OUT_PATH = $(root-dir)/de/inc/sy_soc_pkg.sv
# Package files -> compile first
sy_pkg := 	de/inc/axi_pkg.sv            \
		   	de/inc/dbg_pkg.sv            \
		   	de/inc/sy_pkg.sv             \
		   	de/inc/tl_pkg.sv             \
		   	de/inc/sy_axi.sv             \
		   	de/inc/sy_soc_pkg.sv         \
		   	de/inc/reg_intf.sv           \
		   	de/inc/reg_intf_pkg.sv       \
		   	de/ip/fpu/src/fpnew_pkg.sv   \
		   	de/ip/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv
sy_pkg := $(addprefix $(root-dir), $(sy_pkg))

# utility modules
util := de/utils/rr_arb_tree.sv                \
		de/utils/oneHot2Int.sv                 \
		de/utils/lzc.sv                        \
		de/utils/stream_arbiter_flushable.sv   \
		de/utils/stream_arbiter.sv             \
		de/utils/spill_register.sv             \
		de/utils/sync.sv                       \
		de/utils/pulp_clock_gating.sv          \
		de/utils/sync_wedge.sv                 \
		de/utils/apb_to_reg.sv                 \
		de/utils/fan_ctrl.sv                   \
		de/utils/rstgen_bypass.sv              \
		de/utils/rstgen.sv                     \
		de/utils/sdp_bram_fifo.sv              \
		de/utils/fifo_v3.sv                              					
util := $(addprefix $(root-dir), $(util))

ip := 	$(filter-out de/ip/fpu/src/fpnew_pkg.sv,$(wildcard de/ip/fpu/src/*.sv))   			\
		$(filter-out de/ip/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv,    				\
		$(wildcard de/ip/fpu/src/fpu_div_sqrt_mvp/hdl/*.sv))                					\
		$(wildcard de/ip/sram/*.sv)                                            					\
		$(wildcard de/ip/rv_plic/rtl/*.sv)                                            			\
		$(filter-out de/ip/apb_uart/src/reg_uart_warp.sv,$(wildcard de/ip/apb_uart/src/*.sv))\
		de/ip/algebra/div64x64_d20_wrap.sv														\
		de/ip/algebra/mul64x64_d3_wrap.sv													
                                	
ip := $(addprefix $(root-dir), $(ip))

src :=  $(wildcard de/src/sy/sy_ppl/*.sv)              									\
		$(wildcard de/src/sy/sy_tl/tl_buffer/*.sv)              						\
		$(wildcard de/src/sy/sy_tl/tl_xbar/*.sv)              							\
		$(wildcard de/src/sy/sy_tl/tl_connect/*.sv)              						\
		$(wildcard de/src/sy/sy_tl/tl2amba/*.sv)              							\
		$(wildcard de/src/sy/sy_tl/*.sv)              									\
		$(wildcard de/src/sy/sy_cache/sy_dcache/*.sv)              						\
		$(wildcard de/src/sy/sy_cache/*.sv)              								\
		$(wildcard de/src/sy/sy_clint/*.sv)              								\
		$(wildcard de/src/sy/sy_plic/*.sv)              								\
		$(wildcard de/src/sy/sy_mmu/*.sv)              									\
		$(wildcard de/src/sy/sy_dma/*.sv)              									\
		$(wildcard de/src/sy/*.sv)              												
src := $(addprefix $(root-dir), $(src))

fpga_src := $(wildcard de/ip/bootrom_fpga/*.sv) 	\
			de/src/sy_soc_fpga.sv
fpga_src := $(addprefix $(root-dir), $(fpga_src))

gen_src : 
	@echo "[Generate Source files] Generate sources"
	cd ${SCRIPTS_DIR} && make all CONFIG_FILE=$(CONFIG_FILE) DTS_OUT_PATH=$(DTS_OUT_PATH) SOC_OUT_PATH=$(SOC_OUT_PATH)
	@echo "[Generate Source files Done]" 

fpga: $(sy_pkg) $(ip) $(util) $(src) $(fpga_src) 
	@echo "[FPGA] Generate sources"
	@echo read_verilog -sv {$(sy_pkg)}   > fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(ip)} 		 >> fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(util)}     >> fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(src)} 	 >> fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(fpga_src)} >> fpga/xilinx_scripts/add_sources.tcl
	@echo "[FPGA] Generate Bitstream"
	cd fpga && make BOARD="vc707" XILINX_PART="xc7vx485tffg1761-2" XILINX_BOARD="xilinx.com:vc707:part0:1.3" CLK_PERIOD_NS="20"

fpga_gui: $(sy_pkg) $(ip) $(util) $(src) $(fpga_src) 
	@echo "[FPGA] Generate sources"
	@echo read_verilog -sv {$(sy_pkg)}   > fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(ip)} 		 >> fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(util)}     >> fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(src)} 	 >> fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(fpga_src)} >> fpga/xilinx_scripts/add_sources.tcl
	@echo "[FPGA] Generate Bitstream"
	cd fpga && make prj_gui BOARD="vc707" XILINX_PART="xc7vx485tffg1761-2" XILINX_BOARD="xilinx.com:vc707:part0:1.3" CLK_PERIOD_NS="20"

.PHONY: fpga

clean: 
	cd de/ip/bootrom_fpga && make clean
	cd fpga && make clean