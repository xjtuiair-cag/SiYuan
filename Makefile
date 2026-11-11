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
SCRIPTS_DIR := $(ROOT_DIR)scripts
CPU_VC      := $(DE_HOME)/vc/cpu.vc
EXPAND_VC   := $(SCRIPTS_DIR)/expand_vc.py

# -----------------------------------------------------------------------------
# User knobs
# -----------------------------------------------------------------------------
BOARD        ?= vc707
# BOOTROM_TYPE: normal | lowrisc
BOOTROM_TYPE ?= normal
# CORE_NUM selects hart count for sim + FPGA via +define+/verilog_define SY_CORE_NUM
CORE_NUM     ?= 2
TEST         ?= core0_rv64ui-p-add
SEED         ?= 0
BOOTMODE     ?= 1
TEST_LIST    ?= all_test_list.txt

ifeq ($(filter $(CORE_NUM),1 2 3 4),)
$(error Unsupported CORE_NUM=$(CORE_NUM). Supported: 1 2 3 4)
endif

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
# Per-config build tree (parallel-safe across BOARD / BOOTROM_TYPE / CORE_NUM)
#   fpga/build/<BOARD>/<BOOTROM_TYPE>_<N>cores/{bootrom,ip,...}
# -----------------------------------------------------------------------------
CONFIG_NAME     := $(BOOTROM_TYPE)_$(CORE_NUM)cores
FPGA_BUILD_DIR  := $(FPGA_DIR)/build/$(BOARD)/$(CONFIG_NAME)
FPGA_IP_DIR     := $(FPGA_BUILD_DIR)/ip
BOOTROM_SRC     := $(FPGA_DIR)/bootrom/bootrom_$(BOOTROM_TYPE)
BOOTROM_WORK    := $(FPGA_BUILD_DIR)/bootrom
ADD_SOURCES_TCL := $(FPGA_BUILD_DIR)/add_sources.tcl

ifeq ($(BOOTROM_TYPE),normal)
	BOOTROM_SV      := $(BOOTROM_WORK)/bootrom.sv
	BOOTROM_DEFINES := NORMAL
	DTS_OUT_PATH    := $(BOOTROM_WORK)/sy.dts
else ifeq ($(BOOTROM_TYPE),lowrisc)
	BOOTROM_SV      := $(BOOTROM_WORK)/bootrom_lowrisc.sv
	BOOTROM_DEFINES := LOWRISC
	DTS_OUT_PATH    := $(BOOTROM_WORK)/sy.dts
else
$(error Unknown BOOTROM_TYPE=$(BOOTROM_TYPE). Supported: normal, lowrisc)
endif

# Shared by Vivado (verilog_define) and documented for sim (+define+)
CORE_DEFINE    := SY_CORE_NUM=$(CORE_NUM)
VIVADO_DEFINES := $(BOARD_DEFINES) $(BOOTROM_DEFINES) $(CORE_DEFINE)

FPGA_TOP_SV     := $(FPGA_DIR)/fpga_src/$(FPGA_TOP).sv
CPU_BOOTROM_SV  := $(FPGA_DIR)/fpga_src/cpu_bootrom.sv

# Extra FPGA-only RTL not covered by cpu.vc
FPGA_EXTRA_SRCS := \
	$(FPGA_TOP_SV) \
	$(CPU_BOOTROM_SV) \
	$(BOOTROM_SV)

export DE_HOME DV_HOME BOARD XILINX_PART XILINX_BOARD CLK_PERIOD_NS FPGA_TOP
export VIVADO_DEFINES CORE_NUM

# Sync bootrom sources into the per-config workdir without clobbering generated
# outputs (sy.dts / *.sv / objects). Safe for concurrent make fpga jobs.
define sync_bootrom_workdir
	@mkdir -p $(BOOTROM_WORK)
	@if command -v rsync >/dev/null 2>&1; then \
		rsync -a \
			--exclude='*.o' --exclude='*.elf' --exclude='*.bin' --exclude='*.img' \
			--exclude='*.sv' --exclude='*.dtb' --exclude='*.dis' --exclude='*.s' \
			--exclude='*.mem' --exclude='*.vlog' --exclude='mapfile' --exclude='cnvmem' \
			--exclude='sy.dts' --exclude='sy.dtb' \
			"$(BOOTROM_SRC)/" "$(BOOTROM_WORK)/"; \
	else \
		cp -a "$(BOOTROM_SRC)/." "$(BOOTROM_WORK)/"; \
		$(MAKE) -C "$(BOOTROM_WORK)" clean; \
		if [ -d "$(BOOTROM_WORK)/boot0" ]; then $(MAKE) -C "$(BOOTROM_WORK)/boot0" clean; fi; \
	fi
endef

# =============================================================================
# Help
# =============================================================================
.PHONY: help
help:
	@echo "SiYuan top-level targets"
	@echo ""
	@echo "  Config:"
	@echo "    make gen_src [CORE_NUM=1|2|3|4]   # DTS only (address map fixed in sy_pkg.sv)"
	@echo "    CORE_NUM -> +define+/verilog_define SY_CORE_NUM for sim and Vivado"
	@echo ""
	@echo "  Simulation (runs under dv/simulation):"
	@echo "    make sim      [CORE_NUM=2]                        # force recompile RTL"
	@echo "    make run      TEST=<name> [CORE_NUM=2] [BOOTMODE=1] [SEED=0]"
	@echo "    make run_gui  TEST=<name> [CORE_NUM=2] [BOOTMODE=1] [SEED=0]"
	@echo "      (run/run_gui reuse cpu.simv; recompile only if missing or CORE_NUM changed)"
	@echo "    make regression [TEST_LIST=all_test_list.txt]"
	@echo ""
	@echo "  Bootrom:"
	@echo "    make bootrom [BOARD=vc707] [BOOTROM_TYPE=normal|lowrisc] [CORE_NUM=2]"
	@echo "      builds under fpga/build/<BOARD>/<BOOTROM_TYPE>_<N>cores/bootrom/"
	@echo ""
	@echo "  FPGA (configs are isolated — parallel make fpga jobs are OK):"
	@echo "    make fpga     [BOARD=vc707|genesys2] [BOOTROM_TYPE=normal|lowrisc] [CORE_NUM=2]"
	@echo "    make fpga_gui [BOARD=vc707|genesys2] [BOOTROM_TYPE=normal|lowrisc] [CORE_NUM=2]"
	@echo "    tree: fpga/build/<BOARD>/<BOOTROM_TYPE>_<N>cores/{bootrom,ip,*.bit}"
	@echo ""
	@echo "  Clean:"
	@echo "    make clean"
	@echo ""
	@echo "RTL filelist: $(CPU_VC)"

# =============================================================================
# Config generation — DTS only (CORE_NUM). Address map is fixed in sy_pkg.sv.
# =============================================================================
.PHONY: gen_src dts bootrom_workdir

gen_src: dts

bootrom_workdir:
	@test -d "$(BOOTROM_SRC)" || (echo "missing bootrom sources: $(BOOTROM_SRC)" && exit 1)
	$(sync_bootrom_workdir)

dts: bootrom_workdir
ifeq ($(BOOTROM_TYPE),normal)
	@echo "[GEN] Device tree CORE_NUM=$(CORE_NUM) -> $(DTS_OUT_PATH)"
	cd $(SCRIPTS_DIR) && python gen_dts.py -n $(CORE_NUM) -o $(DTS_OUT_PATH)
else
	@echo "[GEN] skip DTS for BOOTROM_TYPE=$(BOOTROM_TYPE) (uses generic.dts in workdir)"
endif

# =============================================================================
# Simulation — launched from repo root; CORE_NUM -> +define+SY_CORE_NUM
# =============================================================================
.PHONY: sim cpu_sim run run_gui regression

# Shared args for dv/simulation Makefile
SIM_MAKE_ARGS := DE_HOME="$(DE_HOME)" DV_HOME="$(DV_HOME)" CORE_NUM="$(CORE_NUM)" \
	TEST="$(TEST)" SEED="$(SEED)"

sim cpu_sim:
	@echo "[SIM] Compile CORE_NUM=$(CORE_NUM) (SY_CORE_NUM=$(CORE_NUM))"
	cd $(SIM_DIR) && . ./setup_env.sh && $(MAKE) cpu_sim $(SIM_MAKE_ARGS)

run:
	@echo "[SIM] Run TEST=$(TEST) CORE_NUM=$(CORE_NUM) BOOTMODE=$(BOOTMODE) SEED=$(SEED)"
	cd $(SIM_DIR) && . ./setup_env.sh && BOOTMODE="$(BOOTMODE)" $(MAKE) run $(SIM_MAKE_ARGS)

run_gui:
	@echo "[SIM] GUI TEST=$(TEST) CORE_NUM=$(CORE_NUM) BOOTMODE=$(BOOTMODE) SEED=$(SEED)"
	cd $(SIM_DIR) && . ./setup_env.sh && BOOTMODE="$(BOOTMODE)" $(MAKE) run_gui $(SIM_MAKE_ARGS)

regression:
	@echo "[SIM] Regression ($(TEST_LIST))"
	cd $(SIM_DIR) && . ./setup_env.sh && python3 run_regression.py $(TEST_LIST)

# =============================================================================
# Bootrom — copy sources into per-config workdir, then compile there
# =============================================================================
.PHONY: bootrom bootrom_normal bootrom_lowrisc

bootrom: bootrom_$(BOOTROM_TYPE)

bootrom_normal: dts
	@echo "[BOOTROM] Build normal in $(BOOTROM_WORK) (CORE_NUM=$(CORE_NUM))"
	$(MAKE) -C $(BOOTROM_WORK) all
	@test -f "$(BOOTROM_SV)" || (echo "missing $(BOOTROM_SV)" && exit 1)

bootrom_lowrisc: bootrom_workdir
	@echo "[BOOTROM] Build lowrisc in $(BOOTROM_WORK) (BOARD=$(BOARD))"
	$(MAKE) -C $(BOOTROM_WORK)/boot0 all
	$(MAKE) -C $(BOOTROM_WORK) BOARD=$(BOARD) all
	@test -f "$(BOOTROM_SV)" || (echo "missing $(BOOTROM_SV)" && exit 1)

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
	@echo "[FPGA] Sources ready CONFIG=$(CONFIG_NAME) TOP=$(FPGA_TOP) CORE_NUM=$(CORE_NUM)"

fpga: fpga_sources
	@echo "[FPGA] Build bitstream BOARD=$(BOARD) CONFIG=$(CONFIG_NAME)"
	@echo "[FPGA] Project: $(FPGA_BUILD_DIR)"
	@echo "[FPGA] IP:      $(FPGA_IP_DIR)"
	$(MAKE) -C $(FPGA_DIR) \
		BOARD=$(BOARD) \
		BOOTROM_TYPE=$(BOOTROM_TYPE) \
		CORE_NUM=$(CORE_NUM) \
		CONFIG_NAME=$(CONFIG_NAME) \
		ADD_SOURCES_TCL=$(ADD_SOURCES_TCL) \
		XILINX_PART=$(XILINX_PART) \
		XILINX_BOARD=$(XILINX_BOARD) \
		CLK_PERIOD_NS=$(CLK_PERIOD_NS) \
		FPGA_TOP=$(FPGA_TOP) \
		VIVADO_DEFINES="$(VIVADO_DEFINES)"

fpga_gui: fpga_sources
	@echo "[FPGA] Open Vivado GUI BOARD=$(BOARD) CONFIG=$(CONFIG_NAME)"
	@echo "[FPGA] Project: $(FPGA_BUILD_DIR)"
	@echo "[FPGA] IP:      $(FPGA_IP_DIR)"
	$(MAKE) -C $(FPGA_DIR) prj_gui \
		BOARD=$(BOARD) \
		BOOTROM_TYPE=$(BOOTROM_TYPE) \
		CORE_NUM=$(CORE_NUM) \
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
	-$(MAKE) -C $(SIM_DIR) clean DE_HOME="$(DE_HOME)" DV_HOME="$(DV_HOME)"
	-$(MAKE) -C $(FPGA_DIR) clean
	@rm -f $(FPGA_DIR)/xilinx_scripts/add_sources.tcl

clean_test:
	-$(MAKE) -C $(SIM_DIR) clean_test DE_HOME="$(DE_HOME)" DV_HOME="$(DV_HOME)"
