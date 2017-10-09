#-------------------------------------------------------------------------------
# Verilator options
#-------------------------------------------------------------------------------

VERILATOR = verilator
# VFLAGS    = -Wall
VFLAGS    = -Wno-UNUSED

CFLAGS    = -std=c++14 -Wall -g
CFLAGS   += -O0
LDFLAGS   = -lyaml-cpp

OUTPUT    = -cc
TRACE     = --trace --trace-structs


#-------------------------------------------------------------------------------
# RTL Sources
#-------------------------------------------------------------------------------

RTL_ROOT = ../../../src/rtl
MODULE_DIR = $(RTL_ROOT)/tia1a
SIM_MODULE = tia1a


#-------------------------------------------------------------------------------
# Build
#-------------------------------------------------------------------------------

all: run_screen

run_sim: obj_dir/V$(SIM_MODULE)
	./obj_dir/V$(SIM_MODULE)

obj_dir/V$(SIM_MODULE): sim_$(SIM_MODULE).cpp
	$(VERILATOR) $(OUTPUT) $(TRACE) $(VFLAGS) \
		-CFLAGS "$(CFLAGS)" -LDFLAGS "$(LDFLAGS)" \
		-I$(MODULE_DIR) $(SIM_MODULE).v --exe $^
	make -C obj_dir -f V$(SIM_MODULE).mk

run_screen: obj_dir/V$(SIM_MODULE) sim_tia1a.yml
	make run_sim
	make bin2img

sim_tia1a.yml: $(wildcard tiasm/*.tiasm)
	cat sim_tia1a_sync.yml > $@
	echo "" >> $@
	echo "# ------------------------------------------------------------------------------" >> $@
	echo "# Test screen" >> $@
	echo "# ------------------------------------------------------------------------------" >> $@
	echo "" >> $@
	python tiasm.py $^ >> $@

bin2img:
	for b in `ls ./*.bin`; do python bin2img.py $${b}; done

clean:
	rm -rf obj_dir *.vcd

clean_screen:
	rm -rf *.bin *.png
