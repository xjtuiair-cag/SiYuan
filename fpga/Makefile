# FPGA bitstream build.
#
# Layout under fpga/build (one fully isolated tree per config — parallel-safe):
#   build/<BOARD>/<BOOTROM_TYPE>_<N>cores/
#     bootrom/     copied + compiled bootrom sources
#     ip/<ip>/     Xilinx IP copied from xilinx_ip/ and compiled here
#     *.bit/*.mcs  Vivado project outputs
#
# IP sources stay in xilinx_ip/. They are copied into this config's ip/ directory
# and compiled there. The Vivado project reads the XCI from the IP's own .srcs
# tree so OUTPUTDIR (.gen) stays under this config, not under fpga/build/*.gen.

VIVADO ?= vivado
FPGA_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
VIVADOFLAGS ?= -nojournal -mode batch -source $(FPGA_ROOT)/xilinx_scripts/prologue.tcl
PRJ_NAME = SiYuan
FPGA_TOP ?= cpu_vc707_top

BOARD ?= vc707
BOOTROM_TYPE ?= normal
CORE_NUM ?= 2
CONFIG_NAME ?= $(BOOTROM_TYPE)_$(CORE_NUM)cores

export BOARD XILINX_PART XILINX_BOARD CLK_PERIOD_NS FPGA_TOP VIVADO_DEFINES
export FPGA_ROOT

ip-src-dir := $(FPGA_ROOT)/xilinx_ip
build-dir := $(FPGA_ROOT)/build/$(BOARD)/$(CONFIG_NAME)
ip-dir := $(build-dir)/ip
IP_BUILD_DIR := $(ip-dir)
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
# RUNTIME_PARAM.OUTPUTDIR resolves to <ip>/<ip>.gen/ under this config's ip/.
ips := $(foreach ip,$(ip-names),$(ip-dir)/$(ip)/$(ip).srcs/sources_1/ip/$(ip)/$(ip).xci)

all: $(mcs)

$(build-dir):
	mkdir -p $(build-dir)

# Copy one IP's sources out of xilinx_ip/ and compile in this config's ip/.
# $(1) is the IP directory name.
define build_one_ip
$(ip-dir)/$(1)/$(1).srcs/sources_1/ip/$(1)/$(1).xci: $(ip-src-dir)/$(1)/Makefile $(ip-src-dir)/$(1)/tcl/run.tcl $(ip-src-dir)/common.mk $(wildcard $(ip-src-dir)/$(1)/*.prj)
	@echo "[IP] Copy and build $(1) BOARD=$(BOARD) CONFIG=$(CONFIG_NAME) -> $(ip-dir)/$(1)"
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
	@echo "[FPGA] Config IP directory: $(ip-dir)"
	cd $(build-dir) && $(VIVADO) $(VIVADOFLAGS) -source $(FPGA_ROOT)/xilinx_scripts/run.tcl
	cp -f $(build-dir)/SiYuan.runs/impl_1/$(FPGA_TOP)* $(build-dir)/

mcs: $(mcs)

prj_gui: $(ips) $(ADD_SOURCES_TCL) | $(build-dir)
	@echo "[FPGA] Project directory: $(build-dir)"
	@echo "[FPGA] Config IP directory: $(ip-dir)"
	cd $(build-dir) && $(VIVADO) $(VIVADOFLAGS) -source $(FPGA_ROOT)/xilinx_scripts/create_prj.tcl \
		&& $(VIVADO) $(PRJ_NAME).xpr

program:
	$(VIVADO) $(VIVADOFLAGS) -source $(FPGA_ROOT)/xilinx_scripts/program.tcl

# Wipe generated IP for this config only (or all of build/ via clean).
clean_ip:
	rm -rf $(ip-dir)

clean:
	rm -rf $(FPGA_ROOT)/build

.PHONY: all mcs prj_gui program clean clean_ip
