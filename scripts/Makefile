.PHONY: lint build sim
# Include *.mk for files list
include ${PROJVAR_PROJECT_ROOT}/scripts/funcsim.mk

TOP_SIM = Design_sim
TOP_RTL = Design

lint:
	verilator -f ${PROJVAR_PROJECT_ROOT}/scripts/verilator/verilator_config_lint.f \
		--top $(TOP_RTL) $(RTL_SRCFILES) -I$(RTL_INCDIRS)

build:
	rm -rf run_dir_verilator
	verilator -f ${PROJVAR_PROJECT_ROOT}/scripts/verilator/verilator_config_sim.f \
    --top $(TOP_SIM) $(RTL_SRCFILES) -I$(RTL_INCDIRS) $(SIM_SRCFILES) 

sim:
	./run_dir_verilator/V$(TOP_SIM)

wave:
	gtkwave wave.vcd wave.gtkw 2>/dev/null

clean:
	rm -rf run_dir_verilator
	rm -f *.vcd

