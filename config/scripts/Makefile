CONFIG_FILE = base 
DTS_OUT_PATH = none
SOC_OUT_PATH = none
all: dts plic soc

dts:
	@echo "Generate dts file"
	python gen_dts.py -f $(CONFIG_FILE) -o $(DTS_OUT_PATH)
	@echo "Dts file Generation Done"

plic:
	@echo "Generate plic file"
	python gen_plic.py -f $(CONFIG_FILE) 
	@echo "Plic file Generation Done"

soc:
	@echo "Generate Soc file"
	python gen_soc_pkg.py -f $(CONFIG_FILE) -o $(SOC_OUT_PATH)
	cd ../../de/rtl/ip/bootrom_fpga && make clean && make all
	@echo "Soc file Generation Done"