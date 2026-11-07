# Author: shenghuan liu
# Description: Top-level Makefile for SiYuan (sim + FPGA).
#              RTL file lists live in de/vc/cpu.vc — do not hardcode sources here.

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT_DIR    := $(dir $(mkfile_path))

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------
DE_HOME     := $(ROOT_DIR)de
DV_HOME     := $(ROOT_DIR)dv
FPGA_DIR    := $(ROOT_DIR)fpga
SIM_DIR     := $(DV_HOME)/simulation
SCRIPTS_DIR := $(ROOT_DIR)config/scripts
CPU_VC      := $(DE_HOME)/vc/cpu.vc
EXPAND_VC   := $(SCRIPTS_DIR)/expand_vc.py

# -----------------------------------------------------------------------------
# User knobs
# -----------------------------------------------------------------------------
BOARD        ?= vc707
# BOOTROM_TYPE: normal | lowrisc
BOOTROM_TYPE ?= normal
# CONFIG is the yaml stem under config/, e.g. 2_cores or 4_cores (no .yaml)
CONFIG       ?= 2_cores
TEST         ?= core0_rv64ui-p-add
SEED         ?= 0
BOOTMODE     ?= 1
TEST_LIST    ?= all_test_list.txt

CONFIG_NAME  := $(patsubst %.yaml,%,$(notdir $(CONFIG)))
CONFIG_FILE  := $(ROOT_DIR)config/$(CONFIG_NAME).yaml
SOC_OUT_PATH := $(DE_HOME)/inc/sy_soc_pkg.sv
# normal bootrom embeds this DTS; generate it in place
DTS_OUT_PATH := $(FPGA_DIR)/bootrom/bootrom_normal/sy.dts

# -----------------------------------------------------------------------------
# Board parameters
# -----------------------------------------------------------------------------
ifeq ($(BOARD),genesys2)
	XILINX_PART   := xc7k325tffg900-2
	XILINX_BOARD  := digilentinc.com:genesys2:part0:1.1
	CLK_PERIOD_NS := 20
	FPGA_TOP      := cpu_genesys2_top
	BOARD_DEFINES := GENESYS2 PLATFORM_XILINX
else ifeq ($(BOARD),vc707)
	XILINX_PART   := xc7vx485tffg1761-2
	XILINX_BOARD  := xilinx.com:vc707:part0:1.3
	CLK_PERIOD_NS := 20
	FPGA_TOP      := cpu_vc707_top
	BOARD_DEFINES := VC707 PLATFORM_XILINX
else
$(error Unknown BOARD=$(BOARD). Supported: vc707, genesys2)
endif

# -----------------------------------------------------------------------------
# Bootrom selection
# -----------------------------------------------------------------------------
ifeq ($(BOOTROM_TYPE),normal)
	BOOTROM_DIR     := $(FPGA_DIR)/bootrom/bootrom_normal
	BOOTROM_SV      := $(BOOTROM_DIR)/bootrom.sv
	BOOTROM_DEFINES := NORMAL
else ifeq ($(BOOTROM_TYPE),lowrisc)
	BOOTROM_DIR     := $(FPGA_DIR)/bootrom/bootrom_lowrisc
	BOOTROM_SV      := $(BOOTROM_DIR)/bootrom_lowrisc.sv
	BOOTROM_DEFINES := LOWRISC
else
$(error Unknown BOOTROM_TYPE=$(BOOTROM_TYPE). Supported: normal, lowrisc)
endif

VIVADO_DEFINES := $(BOARD_DEFINES) $(BOOTROM_DEFINES)

FPGA_TOP_SV     := $(FPGA_DIR)/fpga_src/$(FPGA_TOP).sv
CPU_BOOTROM_SV  := $(FPGA_DIR)/fpga_src/cpu_bootrom.sv

# fpga/build/<board>/<bootrom>/<config>/  — one Vivado project per combination.
# fpga/build/<board>/ip/                  — Xilinx IP compiled for that board.
FPGA_BUILD_DIR  := $(FPGA_DIR)/build/$(BOARD)/$(BOOTROM_TYPE)/$(CONFIG_NAME)
FPGA_IP_DIR     := $(FPGA_DIR)/build/$(BOARD)/ip
ADD_SOURCES_TCL := $(FPGA_BUILD_DIR)/add_sources.tcl

# Extra FPGA-only RTL not covered by cpu.vc
FPGA_EXTRA_SRCS := \
	$(FPGA_TOP_SV) \
	$(CPU_BOOTROM_SV) \
	$(BOOTROM_SV)

export DE_HOME DV_HOME BOARD XILINX_PART XILINX_BOARD CLK_PERIOD_NS FPGA_TOP
export VIVADO_DEFINES

# =============================================================================
# Help
# =============================================================================
.PHONY: help
help:
	@echo "SiYuan top-level targets"
	@echo ""
	@echo "  Config:"
	@echo "    make gen_src [CONFIG=2_cores|4_cores] [BOOTROM_TYPE=normal|lowrisc]"
	@echo ""
	@echo "  Simulation (runs under dv/simulation):"
	@echo "    make sim                                      # compile RTL (cpu_sim)"
	@echo "    make run     TEST=<name> [BOOTMODE=1] [SEED=0]# batch run"
	@echo "    make run_gui TEST=<name> [BOOTMODE=1] [SEED=0]# GUI run"
	@echo "    make regression [TEST_LIST=all_test_list.txt] # regression"
	@echo ""
	@echo "  Bootrom:"
	@echo "    make bootrom [BOOTROM_TYPE=normal|lowrisc]"
	@echo ""
	@echo "  FPGA:"
	@echo "    make fpga     [BOARD=vc707|genesys2] [BOOTROM_TYPE=normal|lowrisc] [CONFIG=2_cores]"
	@echo "    make fpga_gui [BOARD=vc707|genesys2] [BOOTROM_TYPE=normal|lowrisc] [CONFIG=2_cores]"
	@echo "    project: fpga/build/<BOARD>/<BOOTROM_TYPE>/<CONFIG>/"
	@echo "    IP:      fpga/build/<BOARD>/ip/   (copied from xilinx_ip, then compiled)"
	@echo ""
	@echo "  Clean:"
	@echo "    make clean"
	@echo ""
	@echo "RTL filelist: $(CPU_VC)"

# =============================================================================
# Config generation (sy_soc_pkg + dts). Bootrom build is separate.
# =============================================================================
.PHONY: gen_src dts soc_pkg
gen_src: dts soc_pkg

dts:
	@echo "[GEN] Device tree -> $(DTS_OUT_PATH)"
	@mkdir -p $(dir $(DTS_OUT_PATH))
	cd $(SCRIPTS_DIR) && python gen_dts.py -f $(CONFIG_FILE) -o $(DTS_OUT_PATH)

soc_pkg:
	@echo "[GEN] SoC package -> $(SOC_OUT_PATH)"
	cd $(SCRIPTS_DIR) && python gen_soc_pkg.py -f $(CONFIG_FILE) -o $(SOC_OUT_PATH)

# =============================================================================
# Simulation — delegate to dv/simulation
# =============================================================================
.PHONY: sim cpu_sim run run_gui regression

sim cpu_sim:
	@echo "[SIM] Compile in $(SIM_DIR)"
	cd $(SIM_DIR) && . ./setup_env.sh && $(MAKE) cpu_sim DE_HOME="$(DE_HOME)" DV_HOME="$(DV_HOME)"

run:
	@echo "[SIM] Run TEST=$(TEST) BOOTMODE=$(BOOTMODE) SEED=$(SEED)"
	cd $(SIM_DIR) && . ./setup_env.sh && BOOTMODE="$(BOOTMODE)" $(MAKE) run \
		TEST="$(TEST)" SEED="$(SEED)" DE_HOME="$(DE_HOME)" DV_HOME="$(DV_HOME)"

run_gui:
	@echo "[SIM] GUI run TEST=$(TEST) BOOTMODE=$(BOOTMODE) SEED=$(SEED)"
	cd $(SIM_DIR) && . ./setup_env.sh && BOOTMODE="$(BOOTMODE)" $(MAKE) run_gui \
		TEST="$(TEST)" SEED="$(SEED)" DE_HOME="$(DE_HOME)" DV_HOME="$(DV_HOME)"

regression:
	@echo "[SIM] Regression ($(TEST_LIST))"
	cd $(SIM_DIR) && . ./setup_env.sh && python3 run_regression.py $(TEST_LIST)

# =============================================================================
# Bootrom (FPGA content ROM)
# =============================================================================
.PHONY: bootrom bootrom_normal bootrom_lowrisc

bootrom: bootrom_$(BOOTROM_TYPE)

bootrom_normal:
	@echo "[BOOTROM] Build normal bootrom"
	$(MAKE) -C $(FPGA_DIR)/bootrom/bootrom_normal all

bootrom_lowrisc:
	@echo "[BOOTROM] Build lowrisc boot0 + etherboot"
	$(MAKE) -C $(FPGA_DIR)/bootrom/bootrom_lowrisc/boot0 all
	$(MAKE) -C $(FPGA_DIR)/bootrom/bootrom_lowrisc all

# =============================================================================
# FPGA — expand cpu.vc into Vivado add_sources.tcl, then build
# =============================================================================
.PHONY: fpga_sources fpga fpga_gui

fpga_sources: bootrom
	@echo "[FPGA] Generate $(ADD_SOURCES_TCL) from $(CPU_VC)"
	@mkdir -p $(FPGA_BUILD_DIR)
	@test -f $(CPU_VC) || (echo "missing $(CPU_VC)" && exit 1)
	@test -f $(BOOTROM_SV) || (echo "missing bootrom SV: $(BOOTROM_SV)" && exit 1)
	DE_HOME="$(DE_HOME)" python3 $(EXPAND_VC) $(CPU_VC) --tcl \
		$(foreach f,$(FPGA_EXTRA_SRCS),--extra $(f)) \
		-o $(ADD_SOURCES_TCL)
	@echo "[FPGA] Sources ready (BOOTROM_TYPE=$(BOOTROM_TYPE), TOP=$(FPGA_TOP), CONFIG=$(CONFIG_NAME))"

fpga: fpga_sources
	@echo "[FPGA] Build bitstream BOARD=$(BOARD) BOOTROM_TYPE=$(BOOTROM_TYPE) CONFIG=$(CONFIG_NAME)"
	@echo "[FPGA] Project: $(FPGA_BUILD_DIR)"
	@echo "[FPGA] IP:      $(FPGA_IP_DIR)"
	$(MAKE) -C $(FPGA_DIR) \
		BOARD=$(BOARD) \
		BOOTROM_TYPE=$(BOOTROM_TYPE) \
		CONFIG_NAME=$(CONFIG_NAME) \
		ADD_SOURCES_TCL=$(ADD_SOURCES_TCL) \
		XILINX_PART=$(XILINX_PART) \
		XILINX_BOARD=$(XILINX_BOARD) \
		CLK_PERIOD_NS=$(CLK_PERIOD_NS) \
		FPGA_TOP=$(FPGA_TOP) \
		VIVADO_DEFINES="$(VIVADO_DEFINES)"

fpga_gui: fpga_sources
	@echo "[FPGA] Open Vivado GUI BOARD=$(BOARD) BOOTROM_TYPE=$(BOOTROM_TYPE) CONFIG=$(CONFIG_NAME)"
	@echo "[FPGA] Project: $(FPGA_BUILD_DIR)"
	@echo "[FPGA] IP:      $(FPGA_IP_DIR)"
	$(MAKE) -C $(FPGA_DIR) prj_gui \
		BOARD=$(BOARD) \
		BOOTROM_TYPE=$(BOOTROM_TYPE) \
		CONFIG_NAME=$(CONFIG_NAME) \
		ADD_SOURCES_TCL=$(ADD_SOURCES_TCL) \
		XILINX_PART=$(XILINX_PART) \
		XILINX_BOARD=$(XILINX_BOARD) \
		CLK_PERIOD_NS=$(CLK_PERIOD_NS) \
		FPGA_TOP=$(FPGA_TOP) \
		VIVADO_DEFINES="$(VIVADO_DEFINES)"

# =============================================================================
# Clean
# =============================================================================
.PHONY: clean clean_test
clean:
	-$(MAKE) -C $(FPGA_DIR)/bootrom/bootrom_normal clean
	-$(MAKE) -C $(FPGA_DIR)/bootrom/bootrom_lowrisc/boot0 clean
	-$(MAKE) -C $(FPGA_DIR)/bootrom/bootrom_lowrisc clean
	-$(MAKE) -C $(SIM_DIR) clean DE_HOME="$(DE_HOME)" DV_HOME="$(DV_HOME)"
	-$(MAKE) -C $(FPGA_DIR) clean
	@rm -f $(ADD_SOURCES_TCL)
	@rm -f $(FPGA_DIR)/xilinx_scripts/add_sources.tcl

clean_test:
	-$(MAKE) -C $(SIM_DIR) clean_test DE_HOME="$(DE_HOME)" DV_HOME="$(DV_HOME)"
