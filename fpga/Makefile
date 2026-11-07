# FPGA bitstream build.
#
# Layout under fpga/build:
#   build/<BOARD>/<BOOTROM_TYPE>/<CONFIG_NAME>/   Vivado project, bit, mcs
#   build/<BOARD>/ip/<ip>/                        IP compiled for that board
#
# IP sources stay in xilinx_ip/. They are copied into the board IP directory
# and compiled there (Xilinx IP is part / board specific). The Vivado project
# reads the XCI from the IP's own .srcs tree so OUTPUTDIR (.gen) stays under
# build/<BOARD>/ip/<ip>/, not under fpga/build/.

VIVADO ?= vivado
FPGA_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
VIVADOFLAGS ?= -nojournal -mode batch -source $(FPGA_ROOT)/xilinx_scripts/prologue.tcl
PRJ_NAME = SiYuan
FPGA_TOP ?= cpu_vc707_top

BOARD ?= vc707
BOOTROM_TYPE ?= normal
CONFIG_NAME ?= 2_cores

export BOARD XILINX_PART XILINX_BOARD CLK_PERIOD_NS FPGA_TOP VIVADO_DEFINES
export FPGA_ROOT

ip-src-dir := $(FPGA_ROOT)/xilinx_ip
ip-dir := $(FPGA_ROOT)/build/$(BOARD)/ip
IP_BUILD_DIR := $(ip-dir)
build-dir := $(FPGA_ROOT)/build/$(BOARD)/$(BOOTROM_TYPE)/$(CONFIG_NAME)
ADD_SOURCES_TCL ?= $(build-dir)/add_sources.tcl

export IP_BUILD_DIR ADD_SOURCES_TCL

bit := $(build-dir)/$(FPGA_TOP).bit
mcs := $(build-dir)/$(FPGA_TOP).mcs

ip-names := xlnx_axi_clock_converter \
            xlnx_clk_gen \
            xlnx_mig_7_ddr3 \
            div64x64_d20_s \
            div64x64_d20_us

# Prefer the XCI living under the IP project .srcs tree. Its relative
# RUNTIME_PARAM.OUTPUTDIR resolves to <ip>/<ip>.gen/ under the board IP dir.
ips := $(foreach ip,$(ip-names),$(ip-dir)/$(ip)/$(ip).srcs/sources_1/ip/$(ip)/$(ip).xci)

all: $(mcs)

$(build-dir):
	mkdir -p $(build-dir)

# Copy one IP's sources out of xilinx_ip/ and compile in the per-board dir.
# $(1) is the IP directory name.
define build_one_ip
$(ip-dir)/$(1)/$(1).srcs/sources_1/ip/$(1)/$(1).xci: $(ip-src-dir)/$(1)/Makefile $(ip-src-dir)/$(1)/tcl/run.tcl $(ip-src-dir)/common.mk $(wildcard $(ip-src-dir)/$(1)/*.prj)
	@echo "[IP] Copy and build $(1) for BOARD=$(BOARD) -> $(ip-dir)/$(1)"
	rm -rf "$(ip-dir)/$(1)"
	mkdir -p "$(ip-dir)/$(1)"
	cp -f "$(ip-src-dir)/common.mk" "$(ip-dir)/common.mk"
	cp -f "$(ip-src-dir)/$(1)/Makefile" "$(ip-dir)/$(1)/Makefile"
	cp -a "$(ip-src-dir)/$(1)/tcl" "$(ip-dir)/$(1)/"
	if ls "$(ip-src-dir)/$(1)"/*.prj >/dev/null 2>&1; then cp -f "$(ip-src-dir)/$(1)"/*.prj "$(ip-dir)/$(1)/"; fi
	$$(MAKE) -C "$(ip-dir)/$(1)" all
	@test -f "$(ip-dir)/$(1)/$(1).srcs/sources_1/ip/$(1)/$(1).xci" || \
		(echo "ERROR: missing generated XCI for $(1)" && exit 1)
endef

$(foreach ip,$(ip-names),$(eval $(call build_one_ip,$(ip))))

$(mcs): $(bit)
	cd $(build-dir) && $(VIVADO) $(VIVADOFLAGS) -source $(FPGA_ROOT)/xilinx_scripts/write_cfgmem.tcl -tclargs $(mcs) $(bit)

$(bit): $(ips) $(ADD_SOURCES_TCL) | $(build-dir)
	@echo "[FPGA] Project directory: $(build-dir)"
	@echo "[FPGA] Board IP directory: $(ip-dir)"
	cd $(build-dir) && $(VIVADO) $(VIVADOFLAGS) -source $(FPGA_ROOT)/xilinx_scripts/run.tcl
	cp -f $(build-dir)/SiYuan.runs/impl_1/$(FPGA_TOP)* $(build-dir)/

mcs: $(mcs)

prj_gui: $(ips) $(ADD_SOURCES_TCL) | $(build-dir)
	@echo "[FPGA] Project directory: $(build-dir)"
	@echo "[FPGA] Board IP directory: $(ip-dir)"
	cd $(build-dir) && $(VIVADO) $(VIVADOFLAGS) -source $(FPGA_ROOT)/xilinx_scripts/create_prj.tcl \
		&& $(VIVADO) $(PRJ_NAME).xpr

program:
	$(VIVADO) $(VIVADOFLAGS) -source $(FPGA_ROOT)/xilinx_scripts/program.tcl

# Only wipe generated board IP / projects under build/. Never touch xilinx_ip/.
clean_ip:
	rm -rf $(ip-dir)

clean:
	rm -rf $(FPGA_ROOT)/build

.PHONY: all mcs prj_gui program clean clean_ip
