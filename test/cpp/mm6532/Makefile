#-------------------------------------------------------------------------------
# Verilator options
#-------------------------------------------------------------------------------

VERILATOR = verilator

CFLAGS    = -std=c++14 -Wall -g
CFLAGS   += -O0
LDFLAGS   = -lyaml-cpp

OUTPUT    = -cc
TRACE     = --trace --trace-structs


#-------------------------------------------------------------------------------
# RTL Sources
#-------------------------------------------------------------------------------

RTL_ROOT = ../../../src/rtl
MODULE_DIR = $(RTL_ROOT)/mm6532
SIM_MODULE = mm6532


#-------------------------------------------------------------------------------
# Build
#-------------------------------------------------------------------------------

all: run_sim

obj_dir/V$(SIM_MODULE): sim_$(SIM_MODULE).cpp
	$(VERILATOR) $(OUTPUT) $(TRACE) -Wall \
		-CFLAGS "$(CFLAGS)" -LDFLAGS "$(LDFLAGS)" \
		-I$(MODULE_DIR) $(SIM_MODULE).v --exe $^
	make -C obj_dir -f V$(SIM_MODULE).mk

run_sim: obj_dir/V$(SIM_MODULE)
	./obj_dir/V$(SIM_MODULE)

clean:
	rm -rf obj_dir
