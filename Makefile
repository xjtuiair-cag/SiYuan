# Author: shenghuan liu
# Date: 2025/01/08
# Description: Makefile for SiYuan.
# root path
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
root-dir := $(dir $(mkfile_path))
BOARD ?= vc707
DV_HOME = $(root-dir)/dv
DE_HOME = $(root-dir)/de
SIM_DIR = ./dv/simulation
SIM_TYPE ?= riscv_test
TEST ?= rv64ui-p-add
TEST_REGRESSION = rv64ui
GUI ?= 0
CONFIG ?= base.yaml
CONFIG_FILE = $(addprefix $(root-dir)config/, $(CONFIG))
SCRIPTS_DIR = $(root-dir)config/scripts
DTS_OUT_PATH = $(root-dir)de/ip/bootrom_fpga/sy.dts
SOC_OUT_PATH = $(root-dir)de/inc/sy_soc_pkg.sv

# setting additional xilinx board parameters for the selected board
ifeq ($(BOARD), genesys2)
	XILINX_PART              := xc7k325tffg900-2
	XILINX_BOARD             := digilentinc.com:genesys2:part0:1.1
	CLK_PERIOD_NS            := 20
else ifeq ($(BOARD), vc707)
	XILINX_PART              := xc7vx485tffg1761-2
	XILINX_BOARD             := xilinx.com:vc707:part0:1.3
	CLK_PERIOD_NS            := 20
else
$(error Unknown board - please specify a supported FPGA board)
endif

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

ip := 	$(filter-out de/ip/fpu/src/fpnew_pkg.sv, $(wildcard de/ip/fpu/src/*.sv))   			\
		$(filter-out de/ip/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv,    				\
		$(wildcard de/ip/fpu/src/fpu_div_sqrt_mvp/hdl/*.sv))                					\
		$(wildcard de/ip/sram/*.sv)                                            					\
		$(wildcard de/ip/ethernet/*.sv)                                            				\
		de/ip/rv_plic/rtl/plic_regmap.sv                                            			\
		de/ip/rv_plic/rtl/rv_plic_gateway.sv                                            		\
		de/ip/rv_plic/rtl/rv_plic_target.sv                                            			\
		de/ip/rv_plic/rtl/plic_top.sv                                            			 	\
		$(filter-out de/ip/apb_uart/src/reg_uart_wrap.sv,$(wildcard de/ip/apb_uart/src/*.sv))	\
		de/ip/algebra/div64x64_d20_wrap.sv														\
		de/ip/algebra/mul64x64_d3_wrap.sv													
                                	
ip := $(addprefix $(root-dir), $(ip))

src :=  $(wildcard de/src/sy/sy_ppl/sy_ppl_fet/sy_ppl_br_pred/*.sv)              		\
		$(wildcard de/src/sy/sy_ppl/sy_ppl_fet/*.sv)              						\
		$(wildcard de/src/sy/sy_ppl/*.sv)              									\
		$(wildcard de/src/sy/sy_tl/tl_buffer/*.sv)              						\
		$(wildcard de/src/sy/sy_tl/tl_xbar/*.sv)              							\
		$(wildcard de/src/sy/sy_tl/tl_connect/*.sv)              						\
		$(wildcard de/src/sy/sy_tl/tl2amba/*.sv)              							\
		$(wildcard de/src/sy/sy_tl/*.sv)              									\
		$(wildcard de/src/sy/sy_cache/sy_dcache/*.sv)              						\
		$(wildcard de/src/sy/sy_cache/sy_L2_cache/*.sv)              					\
		$(wildcard de/src/sy/sy_cache/*.sv)              								\
		$(wildcard de/src/sy/sy_clint/*.sv)              								\
		$(wildcard de/src/sy/sy_npu/*.sv)              									\
		$(wildcard de/src/sy/sy_plic/*.sv)              								\
		$(wildcard de/src/sy/sy_mmu/*.sv)              									\
		$(wildcard de/src/sy/sy_dma/*.sv)              									\
		$(wildcard de/src/sy/*.sv)              												
src := $(addprefix $(root-dir), $(src))

fpga_src := $(wildcard de/ip/bootrom_fpga/*.sv) 	
ifeq ($(BOARD), genesys2)
	fpga_src += de/src/sy_soc_genesys2.sv
else ifeq ($(BOARD), vc707)
	fpga_src += de/src/sy_soc_vc707.sv
else
$(error Unknown board - please specify a supported FPGA board)
endif
fpga_src := $(addprefix $(root-dir), $(fpga_src))

sim_src := 	$(wildcard de/ip/bootrom_sim/*.sv)	\
			de/ip/sram/sim/sdp_sram_with_strob.sv \
			de/ip/uart_sim/UART_rec.sv \
			de/src/sy_soc_sim.sv	

ifeq ($(SIM_TYPE),benos) 
	sim_src += dv/tb/axi_mem_benos.sv \
				dv/tb/tb_sy_benos.sv 
else ifeq ($(SIM_TYPE),linux)
	sim_src += dv/tb/axi_mem_linux.sv \
				dv/tb/tb_sy_linux.sv 
else ifeq ($(SIM_TYPE),dma)
	sim_src += dv/tb/axi_mem_dma.sv \
				dv/tb/tb_sy_dma.sv 
else ifeq ($(SIM_TYPE),riscv_test)# TODO
	sim_src += dv/tb/axi_mem_riscv_tests.sv \
				dv/tb/tb_sy_riscv_tests.sv 
else 
$(error Unknown sim type - please specify a supported sim type)
endif

sim_src := $(addprefix $(root-dir), $(sim_src))

ifeq ($(GUI),1) 
	SIM_PARAM += -gui
endif

gen_src : 
	@echo "[Generate Source files] Generate sources"
	cd ${SCRIPTS_DIR} && make all CONFIG_FILE=$(CONFIG_FILE) DTS_OUT_PATH=$(DTS_OUT_PATH) SOC_OUT_PATH=$(SOC_OUT_PATH) TYPE=fpga
	@echo "[Generate Source files Done]" 


fpga: $(sy_pkg) $(ip) $(util) $(src) $(fpga_src) 
	@echo "[FPGA] Generate sources"
	@echo read_verilog -sv {$(sy_pkg)}   > fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(ip)} 		 >> fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(util)}     >> fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(src)} 	 >> fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(fpga_src)} >> fpga/xilinx_scripts/add_sources.tcl
	@echo "[FPGA] Generate Bitstream"
	$(MAKE) -C fpga BOARD=$(BOARD) XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CLK_PERIOD_NS="20"

fpga_gui: $(sy_pkg) $(ip) $(util) $(src) $(fpga_src) 
	@echo "[FPGA] Generate sources"
	@echo read_verilog -sv {$(sy_pkg)}   > fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(ip)} 		 >> fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(util)}     >> fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(src)} 	 >> fpga/xilinx_scripts/add_sources.tcl
	@echo read_verilog -sv {$(fpga_src)} >> fpga/xilinx_scripts/add_sources.tcl
	@echo "[FPGA] Generate Bitstream"
	$(MAKE) -C fpga prj_gui BOARD=$(BOARD) XILINX_PART=$(XILINX_PART) XILINX_BOARD=$(XILINX_BOARD) CLK_PERIOD_NS="20"

prepare_sim_src: 
	@echo "[Build src file]" 
	cd ${SCRIPTS_DIR} && make all CONFIG_FILE=$(CONFIG_FILE) DTS_OUT_PATH=$(DTS_OUT_PATH) SOC_OUT_PATH=$(SOC_OUT_PATH) TYPE=sim
	cd $(DV_HOME)/tests/riscv-tests && make all 

build_sim_src: $(ip) $(sy_pkg) $(util) $(src) $(sim_src)
	@echo "[Prepare Source files]"
	@echo $(sy_pkg)         >  dv/vc/source_list.vc     
	@echo $(ip)        		>> dv/vc/source_list.vc     
	@echo $(util)           >> dv/vc/source_list.vc       
	@echo $(src) 	        >> dv/vc/source_list.vc              
	@echo $(sim_src)        >> dv/vc/source_list.vc          
	cd ${SIM_DIR} && make sy_sim_$(SIM_TYPE) DV_HOME="$(DV_HOME)" DE_HOME="$(DE_HOME)"

run_sim_test:
	cd ${SIM_DIR} && make run_$(SIM_TYPE) TEST="$(TEST)" DV_HOME="$(DV_HOME)" DE_HOME="$(DE_HOME)" GUI="$(SIM_PARAM)"

# only support riscv_tests and non-gui mode
run_sim_regression:
	cd ${SIM_DIR} && make run_$(SIM_TYPE)_regression TEST="$(TEST_REGRESSION)" DV_HOME="$(DV_HOME)" DE_HOME="$(DE_HOME)" 

.PHONY: fpga

clean: 
	cd de/ip/bootrom_fpga && make clean
	cd de/ip/bootrom_sim && make clean
	cd dv/simulation && make clean
	cd dv/tests && make clean
	cd fpga && make clean