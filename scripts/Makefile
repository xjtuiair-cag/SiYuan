CORE_NUM ?= 2
BOARD ?= vc707
BOOTROM_TYPE ?= normal
DTS_OUT_PATH ?= ../fpga/build/$(BOARD)/$(BOOTROM_TYPE)_$(CORE_NUM)cores/bootrom/sy.dts

# Prefer: make -C .. gen_src / bootrom / fpga (copies bootrom into the config dir).
# Address map lives in de/inc/sy_pkg.sv and is no longer generated.
all: dts

dts:
	@mkdir -p $(dir $(DTS_OUT_PATH))
	@echo "Generate dts file (CORE_NUM=$(CORE_NUM)) -> $(DTS_OUT_PATH)"
	python gen_dts.py -n $(CORE_NUM) -o $(DTS_OUT_PATH)
	@echo "Dts file Generation Done"
