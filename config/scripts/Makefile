CONFIG_FILE ?= ../../config/2_cores.yaml
DTS_OUT_PATH ?= ../../fpga/bootrom/bootrom_normal/sy.dts
SOC_OUT_PATH ?= ../../de/inc/sy_soc_pkg.sv

# Bootrom RTL/SW build is handled by the top-level Makefile
# (make bootrom BOOTROM_TYPE=normal|lowrisc), not here.
all: dts soc

dts:
	@echo "Generate dts file"
	python gen_dts.py -f $(CONFIG_FILE) -o $(DTS_OUT_PATH)
	@echo "Dts file Generation Done"

soc:
	@echo "Generate Soc package"
	python gen_soc_pkg.py -f $(CONFIG_FILE) -o $(SOC_OUT_PATH)
	@echo "Soc package Generation Done"