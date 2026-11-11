SEED           ?= 0
TEST           ?= 01_example
CORE_NUM       ?= 2
RISCV_ENV	   = p
SOFTWARE_DIR   = ${DV_HOME}/tests/${TEST}
SIMULATION_DIR = ${DV_HOME}/simulation/works
# Separate compile trees per CORE_NUM so SY_CORE_NUM rebuilds don't collide.
LOG_NAME       = log_$(CORE_NUM)cores
LOG_DIR        = ${SIMULATION_DIR}/${LOG_NAME}
COMP_DIR       = ${LOG_DIR}/comp
SIM_DIR        = ${LOG_DIR}/${TEST}
SIMV           = ${COMP_DIR}/cpu.simv
CORE_STAMP     = ${COMP_DIR}/SY_CORE_NUM
SIM_TYPE	  ?= riscv_test
TEST_DIRS 	  := $(wildcard ${DV_HOME}/tests/*/)

prepare_log_dir:
	$(if $(wildcard $(LOG_DIR)),,mkdir -p $(LOG_DIR))

prepare_comp_dir:
	$(if $(wildcard ${COMP_DIR}),,mkdir -p ${COMP_DIR})

prepare_sim_dir:
	$(if $(wildcard $(SIM_DIR)),,mkdir -p $(SIM_DIR))

software:
	cd ${SOFTWARE_DIR}; \
	make clean; \
	make all; \

# Force (re)compile. Use after RTL changes.
cpu_sim: prepare_log_dir prepare_comp_dir
	@echo "[SIM] vlogan/vcs CORE_NUM=$(CORE_NUM) -> ${COMP_DIR}"
	cd ${COMP_DIR}; \
	vlogan -full64 +v2k -sverilog -ntb_opts -debug_all -debug_access+all -sim_res=1ps -timescale=1ns/1ps -nc \
		-kdb +lint=TFIPC-L +vcs+initreg+random -override_timescale=1ns/1ps +vcs+loopreport \
		-cm line+branch+cond+tgl+fsm+assert \
		+define+PLATFORM_SIM=1 \
		+define+SY_CORE_NUM=$(CORE_NUM) \
		+incdir+${DE_HOME}/src/inc \
		+incdir+${DV_HOME}/tb/sim_inc/ \
		-f ${DE_HOME}/vc/cpu.vc \
		-f ${DV_HOME}/vc/tb_cpu.vc \
		-l compile.log; \
	vcs -full64 -o ${SIMV} -ntb_opts -debug_all -debug_region+cell+encrypt +vcs+dumparrays \
		-LDFLAGS -Wl,--no-as-needed \
		-cm line+branch+cond+tgl+fsm+assert \
		-debug_acc+all+dmptf  -debug_access+all -debug_region+cell+encrypt -top tb_cpu +lint=TFIPC-L \
		+vcs+initreg+random +vcs+loopreport +vpi \
		-l elaborate.log
	@echo $(CORE_NUM) > $(CORE_STAMP)

# Compile only if simv missing or CORE_NUM changed; skip otherwise.
ensure_simv: prepare_log_dir prepare_comp_dir
	@if [ ! -x "$(SIMV)" ] || [ "$$(cat $(CORE_STAMP) 2>/dev/null)" != "$(CORE_NUM)" ]; then \
		$(MAKE) cpu_sim DE_HOME="$(DE_HOME)" DV_HOME="$(DV_HOME)" CORE_NUM="$(CORE_NUM)"; \
	else \
		echo "[SIM] reuse $(SIMV) (CORE_NUM=$(CORE_NUM)); make sim to force rebuild"; \
	fi

run_gui: ensure_simv prepare_sim_dir software
	cp ${SOFTWARE_DIR}/output/* ${SIM_DIR}/; \
	cd ${SIM_DIR}; \
	${SIMV} +vcs+initreg+0 -cm line+branch+cond+tgl+fsm+assert \
	-l run.log +ntb_random_seed=${SEED} -gui

run: ensure_simv prepare_sim_dir software
	cp ${SOFTWARE_DIR}/output/* ${SIM_DIR}/; \
	cd ${SIM_DIR}; \
	${SIMV} +vcs+initreg+0 -cm line+branch+cond+tgl+fsm+assert \
	-cm_dir cpu.simv.vdb -l run.log +ntb_random_seed=${SEED}

.PHONY: clean clean_test cpu_sim ensure_simv run run_gui software prepare_log_dir prepare_comp_dir prepare_sim_dir

clean:
	@rm -rf ${SIMULATION_DIR};

clean_test:
	@$(foreach dir,$(TEST_DIRS),$(MAKE) -C $(dir) clean;)
