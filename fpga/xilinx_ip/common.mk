# Build in the current directory (expected to be a per-board copy under
# fpga/build/<BOARD>/ip/<PROJECT>/). Leave the XCI in .srcs so its relative
# OUTPUTDIR points at ./${PROJECT}.gen here, not at fpga/build/.

all:
	vivado -mode batch -source tcl/run.tcl
	@test -f ${PROJECT}.srcs/sources_1/ip/${PROJECT}/${PROJECT}.xci
	@test -f ${PROJECT}.runs/${PROJECT}_synth_1/${PROJECT}.dcp
	mkdir -p ip
	cp -r ${PROJECT}.srcs/sources_1/ip/${PROJECT}/* ip/.
	cp ${PROJECT}.runs/${PROJECT}_synth_1/${PROJECT}.dcp ip/.

gui:
	vivado -mode gui -source tcl/run.tcl &

clean:
	rm -rf ip
	mkdir -p ip
	rm -rf ${PROJECT}.*
	rm -rf component.xml
	rm -rf vivado*.jou
	rm -rf vivado*.log
	rm -rf vivado*.str
	rm -rf xgui
	rm -rf .Xil