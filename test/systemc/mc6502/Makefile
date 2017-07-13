#-------------------------------------------------------------------------------
# SystemC path
#-------------------------------------------------------------------------------

SYSTEMC_ROOT = /usr/local/systemc-2.3.1
SYSTEMC_INCLUDE = $(SYSTEMC_ROOT)/include
SYSTEMC_LIBDIR  = $(SYSTEMC_ROOT)/lib-linux64


#-------------------------------------------------------------------------------
# Verilator options
#-------------------------------------------------------------------------------

VERILATOR = verilator

CFLAGS    = -std=c++14 -Wall -g
CFLAGS   += -O0
LDFLAGS   = 
LDLIBS    = 

OUTPUT    = -cc
TRACE     = --trace --trace-structs


#-------------------------------------------------------------------------------
# RTL Sources
#-------------------------------------------------------------------------------

RTL_ROOT = ../../../src/rtl


#-------------------------------------------------------------------------------
# Build
#-------------------------------------------------------------------------------

all: run_sim

obj_dir/Vmpu: sim_mpu.cpp
	SYSTEMC_INCLUDE=$(SYSTEMC_INCLUDE) \
	SYSTEMC_LIBDIR=$(SYSTEMC_LIBDIR) \
		$(VERILATOR) $(OUTPUT) $(TRACE) -Wall \
		-CFLAGS "$(CFLAGS)" -LDFLAGS "$(LDFLAGS)" -LDLIBS "$(LDLIBS)" \
		-I$(RTL_ROOT)/mc6502 mpu.v --exe $^
	make -C obj_dir -f Vmpu.mk

run_sim: obj_dir/Vmpu
	./obj_dir/Vmpu

clean:
	rm -rf obj_dir
