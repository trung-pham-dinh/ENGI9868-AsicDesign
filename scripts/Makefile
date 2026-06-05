.PHONY: verilator_lint verilator_build verilator_sim
# Include *.mk for files list
include ${PROJVAR_PROJECT_ROOT}/scripts/funcsim.mk

TOP_SIM ?= Design_sim
TOP_RTL ?= Design
TOP_SYNTH ?= write_fsm
TESTCASE_DIR = ${PROJVAR_PROJECT_ROOT}/funcsim/text_files
TESTCASE_WAVE = waves

# Verilator

verilator_lint:
	verilator -f ${PROJVAR_PROJECT_ROOT}/scripts/verilator/verilator_config_lint.f \
		--top $(TOP_RTL) $(RTL_SRCFILES) -I$(RTL_INCDIRS)

verilator_build:
	rm -rf run_dir_verilator
	verilator -f ${PROJVAR_PROJECT_ROOT}/scripts/verilator/verilator_config_sim.f \
    --top $(TOP_SIM) $(RTL_SRCFILES) -I$(RTL_INCDIRS) $(SIM_SRCFILES) -DGTKW_DUMP=1 

verilator_sim:
	./run_dir_verilator/V$(TOP_SIM)

verilator_wave:
	gtkwave wave.vcd wave.gtkw 2>/dev/null

# Xcelium

make_dirs:
	mkdir -p ${PROJVAR_PROJECT_ROOT}/top_level_libs/top_level_lib
	mkdir -p ${PROJVAR_PROJECT_ROOT}/top_level_libs/top_level_gates_lib
	mkdir -p ${PROJVAR_PROJECT_ROOT}/top_level_libs/top_level_testbench_lib
	mkdir -p ${PROJVAR_PROJECT_ROOT}/syn/work/
	mkdir -p ${PROJVAR_PROJECT_ROOT}/syn/reports/
	mkdir -p ${PROJVAR_PROJECT_ROOT}/syn/db/
	mkdir -p ${PROJVAR_PROJECT_ROOT}/gates

xcelium_compile: make_dirs
	xmvlog -f ${PROJVAR_PROJECT_ROOT}/scripts/xcelium/xcelium_config_compile.f \
		-work top_level_lib -incdir $(RTL_INCDIRS) $(RTL_SRCFILES)
	xmvlog -f ${PROJVAR_PROJECT_ROOT}/scripts/xcelium/xcelium_config_compile.f \
		-work top_level_testbench_lib -incdir $(RTL_INCDIRS) $(SIM_SRCFILES) +define+SIMVISION_DUMP

xcelium_elaborate: xcelium_compile
	xmelab -f ${PROJVAR_PROJECT_ROOT}/scripts/xcelium/xcelium_config_elaborate.f \
	    -work top_level_testbench_lib \
	    top_level_testbench_lib.${TOP_SIM}

xcelium_sim: xcelium_elaborate
	xmsim -messages top_level_testbench_lib.${TOP_SIM}

xcelium_validate_%: xcelium_elaborate
	@echo "======================================================"
	@echo " Running testcase: $*"
	@echo "======================================================"
	rm -f $(TESTCASE_DIR)/dump_data.txt   $(TESTCASE_DIR)/log.txt
	rm -f $(TESTCASE_DIR)/source_data.txt $(TESTCASE_DIR)/expected_data.txt

	touch $(TESTCASE_DIR)/source_data.txt $(TESTCASE_DIR)/expected_data.txt
	cp $(TESTCASE_DIR)/testcases/source_data_$*.txt   $(TESTCASE_DIR)/source_data.txt
	cp $(TESTCASE_DIR)/testcases/expected_data_$*.txt $(TESTCASE_DIR)/expected_data.txt
	rm -rf $*.shm

	xmsim -messages top_level_testbench_lib.top_level_test

	cp $(TESTCASE_DIR)/log.txt        $(TESTCASE_DIR)/testcases/log_$*.txt
	cp $(TESTCASE_DIR)/dump_data.txt  $(TESTCASE_DIR)/testcases/dump_data_$*.txt
	mv waves.shm $*.shm
	@echo " Testcase $* done. Result in $(TESTCASE_DIR)/testcases/log_$*.txt"

#------------------------------------------------------------------------------
# Discover all testcases by scanning for source_data_SIM*.txt
#------------------------------------------------------------------------------
TESTCASES := $(sort $(patsubst $(TESTCASE_DIR)/testcases/source_data_%.txt, %, \
                 $(wildcard $(TESTCASE_DIR)/testcases/source_data_SIM*.txt)))
 
#------------------------------------------------------------------------------
# Default target: run all testcases then print a summary
#------------------------------------------------------------------------------
xcelium_all_test: $(addprefix xcelium_validate_, $(TESTCASES))

xcelium_lint:
	hal -f ${PROJVAR_PROJECT_ROOT}/scripts/xcelium/xcelium_config_compile.f -work top_level_lib -top $(TOP_RTL) -incdir $(RTL_INCDIRS) $(RTL_SRCFILES)

xcelium_wave:
	simvision $(TESTCASE_WAVE).shm -input ${TOP_SIM}.svcf &

# Synopsys DC:
dc_srcs.tcl:
	@echo "set search_path [concat \$$search_path $(RTL_INCDIRS)]" > $@
	@echo "set RTL_SRCFILES {$(RTL_SRCFILES)}" >> $@

synopsys_synth: dc_srcs.tcl make_dirs
	dc_shell -f ../syn/${TOP_SYNTH}.dctcl | tee ../syn/${TOP_SYNTH}.log

clean:
	rm -rf run_dir_verilator
	rm -f *.vcd

