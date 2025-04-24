# This file mostly come from cva6 : https://github.com/openhwgroup/cva6 

VIVADO ?= vivado
VIVADOFLAGS ?= -nojournal -mode batch -source ../xilinx_scripts/prologue.tcl
PRJ_NAME = SiYuan

build-dir := build
bit := $(build-dir)/SiYuan_xilinx.bit
mcs := $(build-dir)/SiYuan_xilinx.mcs
ip-dir := xilinx_ip
ips := xlnx_axi_clock_converter.xci  	\
       xlnx_axi_dwidth_converter.xci 	\
       xlnx_axi_quad_spi.xci         	\
       xlnx_axi_gpio.xci             	\
       xlnx_clk_gen.xci              	\
       xlnx_mig_7_ddr3.xci				\
	   div64x64_d20_s.xci				\
	   div64x64_d20_us.xci				\
	   sdp_512x64sd1.xci				

ips := $(addprefix $(build-dir)/, $(ips))
ips-target := $(join $(addsuffix /ip/, $(addprefix $(ip-dir)/, $(basename $(ips)))), $(ips))

all: $(bit)

# Generate mcs from bitstream
#$(mcs): $(bit)
#	cd $(build-dir)
#	$(VIVADO) $(VIVADOFLAGS) -source ../xilinx_scripts/write_cfgmem.tcl -tclargs $@ $^

$(bit): $(ips)
	cd $(build-dir) && $(VIVADO) $(VIVADOFLAGS) -source ../xilinx_scripts/run.tcl
	cp $(build-dir)/SiYuan.runs/impl_1/sy_soc_fpga* ./$(build-dir)

$(ips): %.xci :
	mkdir -p $(build-dir)
	@echo Generating $(@F)
	@cd $(ip-dir)/$(basename $(@F)) && make clean && make
	@cp $(ip-dir)/$(basename $(@F))/ip/$(@F) $@

clean_ip: $(ips)
	$(foreach dir, $(basename $(^F)), \
		echo "Entering $(dir)"; \
		$(MAKE) -C $(ip-dir)/$(dir) clean;) 

mcs: $(mcs)

prj_gui: $(ips)
	cd $(build-dir) && $(VIVADO) $(VIVADOFLAGS) -source ../xilinx_scripts/create_prj.tcl	\
	&& $(VIVADO) $(PRJ_NAME).xpr

program:
	$(VIVADO) $(VIVADOFLAGS) -source xilinx_scripts/program.tcl

clean:clean_ip
	rm -rf $(build-dir)

.PHONY:
	clean
