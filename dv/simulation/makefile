SEED           = 0
TEST           = 01_example
RISCV_ENV	   = p
SOFTWARE_DIR   = ${DV_HOME}/tests/${TEST}
RISCV_TEST_DIR = ${DV_HOME}/tests/riscv-tests
RISCV_TEST 	   = ${RISCV_TEST_DIR}/isa/${TEST}
PYTHON_SCRIPT  = ${RISCV_TEST_DIR}/../gen_verilog_data.py
MAKE_SCRIPT    = ${RISCV_TEST_DIR}/../makefile
REF_DIR        = ${SOFTWARE_DIR}/ref
SIMULATION_DIR = ${DV_HOME}/simulation/works
LOG_NAME       = log
LOG_DIR        = ${SIMULATION_DIR}/${LOG_NAME}
COMP_DIR       = ${LOG_DIR}/comp
SIM_DIR        = ${LOG_DIR}/${TEST}

prepare_log_dir:
	$(if $(wildcard $(LOG_DIR)),,mkdir -p $(LOG_DIR))

prepare_comp_dir:
	$(if $(wildcard ${COMP_DIR}),,$(if $(wildcard log/comp),ln -s ../log/comp $(LOG_DIR)/., mkdir -p ${COMP_DIR}))

prepare_sim_dir:
	$(if $(wildcard $(SIM_DIR)),,mkdir -p $(SIM_DIR))

prepare_ref_dir:
	$(if $(wildcard $(REF_DIR)),\cp -rf $(REF_DIR)/*.txt $(SIM_DIR)/,)

software:
	cd ${SOFTWARE_DIR}; \
	make clean; \
	make all; \

riscv_test_software:
	cp ${RISCV_TEST} ${SIM_DIR}/; \
	cp ${PYTHON_SCRIPT} ${SIM_DIR}/; \
	cp ${MAKE_SCRIPT} ${SIM_DIR}/;	\
	cd ${SIM_DIR} && make gen_verilog_data output_name=${TEST}; 

sy_sim_benos: prepare_log_dir prepare_comp_dir
	cd ${COMP_DIR}; \
	vlogan -full64 +v2k -sverilog -ntb_opts -debug_all -debug_access+all -sim_res=1ps -timescale=1ns/1ps -nc \
		-kdb +lint=TFIPC-L +vcs+initreg+random -override_timescale=1ns/1ps +vcs+loopreport \
		-cm line+branch+cond+tgl+fsm+assert \
		+define+PLATFORM_SIM=1 \
		+incdir+${DE_HOME}/inc \
		-f ${DV_HOME}/vc/source_list.vc \
		-l compile.log; \
	vcs -full64 -o ${COMP_DIR}/sy.simv -ntb_opts -debug_all -debug_region+cell+encrypt +vcs+dumparrays \
		-LDFLAGS -Wl,--no-as-needed \
		-cm line+branch+cond+tgl+fsm+assert \
		-debug_acc+all+dmptf  -debug_access+all -debug_region+cell+encrypt -top tb_sy_benos +lint=TFIPC-L \
		+vcs+initreg+random +vcs+loopreport +vpi \
		-l elaborate.log

sy_sim_linux: prepare_log_dir prepare_comp_dir
	cd ${COMP_DIR}; \
	vlogan -full64 +v2k -sverilog -ntb_opts -debug_all -debug_access+all -sim_res=1ps -timescale=1ns/1ps -nc \
		-kdb +lint=TFIPC-L +vcs+initreg+random -override_timescale=1ns/1ps +vcs+loopreport \
		-cm line+branch+cond+tgl+fsm+assert \
		+define+PLATFORM_SIM=1 \
		+incdir+${DE_HOME}/inc \
		-f ${DV_HOME}/vc/source_list.vc \
		-l compile.log; \
	vcs -full64 -o ${COMP_DIR}/sy.simv -ntb_opts -debug_all -debug_region+cell+encrypt +vcs+dumparrays \
		-LDFLAGS -Wl,--no-as-needed \
		-cm line+branch+cond+tgl+fsm+assert \
		-debug_acc+all+dmptf  -debug_access+all -debug_region+cell+encrypt -top tb_sy_linux +lint=TFIPC-L \
		+vcs+initreg+random +vcs+loopreport +vpi \
		-l elaborate.log

sy_sim_dma: prepare_log_dir prepare_comp_dir
	cd ${COMP_DIR}; \
	vlogan -full64 +v2k -sverilog -ntb_opts -debug_all -debug_access+all -sim_res=1ps -timescale=1ns/1ps -nc \
		-kdb +lint=TFIPC-L +vcs+initreg+random -override_timescale=1ns/1ps +vcs+loopreport \
		-cm line+branch+cond+tgl+fsm+assert \
		+define+PLATFORM_SIM=1 \
		+incdir+${DE_HOME}/inc \
		-f ${DV_HOME}/vc/source_list.vc \
		-l compile.log; \
	vcs -full64 -o ${COMP_DIR}/sy.simv -ntb_opts -debug_all -debug_region+cell+encrypt +vcs+dumparrays \
		-LDFLAGS -Wl,--no-as-needed \
		-cm line+branch+cond+tgl+fsm+assert \
		-debug_acc+all+dmptf  -debug_access+all -debug_region+cell+encrypt -top tb_sy_dma +lint=TFIPC-L \
		+vcs+initreg+random +vcs+loopreport +vpi \
		-l elaborate.log

sy_sim_riscv_test: prepare_log_dir prepare_comp_dir
	cd ${COMP_DIR}; \
	vlogan -full64 +v2k -sverilog -ntb_opts -debug_all -debug_access+all -sim_res=1ps -timescale=1ns/1ps -nc \
		-kdb +lint=TFIPC-L +vcs+initreg+random -override_timescale=1ns/1ps +vcs+loopreport \
		-cm line+branch+cond+tgl+fsm+assert \
		+define+PLATFORM_SIM=1 \
		+incdir+${DE_HOME}/inc \
		-f ${DV_HOME}/vc/source_list.vc \
		-l compile.log; \
	vcs -full64 -o ${COMP_DIR}/sy.simv -ntb_opts -debug_all -debug_region+cell+encrypt +vcs+dumparrays \
		-LDFLAGS -Wl,--no-as-needed \
		-cm line+branch+cond+tgl+fsm+assert \
		-debug_acc+all+dmptf  -debug_access+all -debug_region+cell+encrypt -top tb_sy_riscv_tests +lint=TFIPC-L \
		+vcs+initreg+random +vcs+loopreport +vpi \
		-l elaborate.log

run_benos: prepare_log_dir prepare_comp_dir prepare_sim_dir prepare_ref_dir software
	cp ${SOFTWARE_DIR}/output/* ${SIM_DIR}/; \
	cd ${SIM_DIR}; \
	${COMP_DIR}/sy.simv +vcs+initreg+0 -cm line+branch+cond+tgl+fsm+assert \
	-l run.log +ntb_random_seed=${SEED} $(GUI)

run_linux: prepare_log_dir prepare_comp_dir prepare_sim_dir prepare_ref_dir 
	cp ${SOFTWARE_DIR}/output/* ${SIM_DIR}/; \
	cd ${SIM_DIR}; \
	${COMP_DIR}/sy.simv +vcs+initreg+0 -cm line+branch+cond+tgl+fsm+assert \
	-l run.log +ntb_random_seed=${SEED} $(GUI)

run_dma: prepare_log_dir prepare_comp_dir prepare_sim_dir prepare_ref_dir software
	cp ${SOFTWARE_DIR}/output/* ${SIM_DIR}/; \
	cd ${SIM_DIR}; \
	${COMP_DIR}/sy.simv +vcs+initreg+0 -cm line+branch+cond+tgl+fsm+assert \
	-l run.log +ntb_random_seed=${SEED} $(GUI)

run_riscv_test: prepare_log_dir prepare_comp_dir prepare_sim_dir prepare_ref_dir riscv_test_software
	cd ${SIM_DIR}; \
	${COMP_DIR}/sy.simv +vcs+initreg+0 -cm line+branch+cond+tgl+fsm+assert \
	-l run.log +ntb_random_seed=${SEED} $(GUI)

run_riscv_test_regression:
	python run_regression.py --test "${TEST}" --env "${RISCV_ENV}"		

clean:
	@rm -rf ${SIMULATION_DIR};

clean_test:
	@rm -rf ${SIM_DIR}
