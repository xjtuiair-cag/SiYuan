SEED           = 0
TEST           = 01_example
RISCV_ENV	   = p
SOFTWARE_DIR   = ${DV_HOME}/tests/${TEST}
SIMULATION_DIR = ${DV_HOME}/simulation/works
LOG_NAME       = log
LOG_DIR        = ${SIMULATION_DIR}/${LOG_NAME}
COMP_DIR       = ${LOG_DIR}/comp
SIM_DIR        = ${LOG_DIR}/${TEST}
SIM_TYPE	  ?= riscv_test
TEST_DIRS 	  := $(wildcard ${DV_HOME}/tests/*/)

prepare_log_dir:
	$(if $(wildcard $(LOG_DIR)),,mkdir -p $(LOG_DIR))

prepare_comp_dir:
	$(if $(wildcard ${COMP_DIR}),,$(if $(wildcard log/comp),ln -s ../log/comp $(LOG_DIR)/., mkdir -p ${COMP_DIR}))

prepare_sim_dir:
	$(if $(wildcard $(SIM_DIR)),,mkdir -p $(SIM_DIR))

software:
	cd ${SOFTWARE_DIR}; \
	make clean; \
	make all; \

cpu_sim : prepare_log_dir prepare_comp_dir
	cd ${COMP_DIR}; \
	vlogan -full64 +v2k -sverilog -ntb_opts -debug_all -debug_access+all -sim_res=1ps -timescale=1ns/1ps -nc \
		-kdb +lint=TFIPC-L +vcs+initreg+random -override_timescale=1ns/1ps +vcs+loopreport \
		-cm line+branch+cond+tgl+fsm+assert \
		+define+PLATFORM_SIM=1 \
		+incdir+${DE_HOME}/src/inc \
		+incdir+${DV_HOME}/tb/sim_inc/ \
		-f ${DE_HOME}/vc/cpu.vc \
		-f ${DV_HOME}/vc/tb_cpu.vc \
		-l compile.log; \
	vcs -full64 -o ${COMP_DIR}/cpu.simv -ntb_opts -debug_all -debug_region+cell+encrypt +vcs+dumparrays \
		-LDFLAGS -Wl,--no-as-needed \
		-cm line+branch+cond+tgl+fsm+assert \
		-debug_acc+all+dmptf  -debug_access+all -debug_region+cell+encrypt -top tb_cpu +lint=TFIPC-L \
		+vcs+initreg+random +vcs+loopreport +vpi \
		-l elaborate.log

run_gui: prepare_log_dir prepare_comp_dir prepare_sim_dir software
	cp ${SOFTWARE_DIR}/output/* ${SIM_DIR}/; \
	cd ${SIM_DIR}; \
	${COMP_DIR}/cpu.simv +vcs+initreg+0 -cm line+branch+cond+tgl+fsm+assert \
	-l run.log +ntb_random_seed=${SEED} -gui

run: prepare_log_dir prepare_comp_dir prepare_sim_dir software
	cp ${SOFTWARE_DIR}/output/* ${SIM_DIR}/; \
	cd ${SIM_DIR}; \
	${COMP_DIR}/cpu.simv +vcs+initreg+0 -cm line+branch+cond+tgl+fsm+assert \
	-cm_dir cpu.simv.vdb -l run.log +ntb_random_seed=${SEED} 

.PHONY: clean clean_test

clean:
	@rm -rf ${SIMULATION_DIR};

clean_test:
	@$(foreach dir,$(TEST_DIRS),$(MAKE) -C $(dir) clean;)