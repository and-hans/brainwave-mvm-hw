TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += accum.sv
VERILOG_SOURCES += mem.sv
VERILOG_SOURCES += dsp_mult.sv
VERILOG_SOURCES += dot8.sv
VERILOG_SOURCES += ctrl.sv
VERILOG_SOURCES += mvm.sv
VERILOG_SOURCES += design.sv

COCOTB_TOPLEVEL = mvm

COCOTB_TEST_MODULES = testbench

include $(shell cocotb-config --makefiles)/Makefile.sim