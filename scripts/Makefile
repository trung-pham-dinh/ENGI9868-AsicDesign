.PHONY: verilator_lint verilator_build verilator_sim
# Include *.mk for files list
include ${PROJVAR_PROJECT_ROOT}/scripts/funcsim.mk

TOP_SIM = Design_sim
TOP_RTL = Design

# Verilator

verilator_lint:
	verilator -f ${PROJVAR_PROJECT_ROOT}/scripts/verilator/verilator_config_lint.f \
		--top $(TOP_RTL) $(RTL_SRCFILES) -I$(RTL_INCDIRS)

verilator_build:
	rm -rf run_dir_verilator
	verilator -f ${PROJVAR_PROJECT_ROOT}/scripts/verilator/verilator_config_sim.f \
    --top $(TOP_SIM) $(RTL_SRCFILES) -I$(RTL_INCDIRS) $(SIM_SRCFILES) -D GTKW_DUMP 

verilator_sim:
	./run_dir_verilator/V$(TOP_SIM)

verilator_wave:
	gtkwave wave.vcd wave.gtkw 2>/dev/null

# Xcelium

xcelium_compile:
	xmvlog -f ${PROJVAR_PROJECT_ROOT}/scripts/xcelium/xcelium_config_compile.f \
		-work top_level_lib -incdir $(RTL_INCDIRS) $(RTL_SRCFILES)
	xmvlog -f ${PROJVAR_PROJECT_ROOT}/scripts/xcelium/xcelium_config_compile.f \
		-work top_level_testbench_lib -incdir $(RTL_INCDIRS) $(SIM_SRCFILES) +define+SIMVISION_DUMP

xcelium_elaborate:
	xmelab -f ${PROJVAR_PROJECT_ROOT}/scripts/xcelium/xcelium_config_elaborate.f \
	    -work top_level_testbench_lib \
	    top_level_testbench_lib.${TOP_SIM}

xcelium_sim:
	xmsim -messages top_level_testbench_lib.${TOP_SIM}

xcelium_lint:
	hal -f ${PROJVAR_PROJECT_ROOT}/scripts/xcelium/xcelium_config_compile.f -work top_level_lib -top $(TOP_RTL) -incdir $(RTL_INCDIRS) $(RTL_SRCFILES)

xcelium_wave:
	simvision waves.shm -input simvision.svcf &



clean:
	rm -rf run_dir_verilator
	rm -f *.vcd

