.PHONY: build sim
# Include *.mk for files list
include ${PROJVAR_PROJECT_ROOT}/sim.mk

TOP_SIM = counter_sim
TOP_RTL = counter
build:
	rm -rf run_dir_verilator
	verilator -f ${PROJVAR_PROJECT_ROOT}/verilator_config_sim.f \
    --top $(TOP_SIM) $(RTL_SRCFILES) -I$(RTL_INCDIRS) $(SIM_SRCFILES) 

sim:
	./run_dir_verilator/V$(TOP_SIM)

wave:
	gtkwave wave.vcd wave.gtkw 2>/dev/null

clean:
	rm -rf run_dir_verilator
	rm -f *.vcd

