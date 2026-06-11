# Makefile for MIPS Processor (Class 12 - Sync with Class 11)
# Targets:
#   make         : Compile and run simulation
#   make wave    : Open GTKWave
#   make clean   : Remove generated files

SRC = mips.v control_unit.v hazard_unit.v \
      main_decoder.v alu_decoder.v \
      datapath.v pc.v instruction_memory.v \
      reg_file.v alu.v data_memory.v \
      pwm_controller.v

TB  = mips_tb.v
OUT = mips.out
VCD = mips.vcd

all: compile run

compile:
	iverilog -Wall -o $(OUT) $(TB) $(SRC)

run:
	vvp -n $(OUT)

wave:
	gtkwave $(VCD) &

clean:
	-del /Q $(OUT) 2>NUL
	-del /Q $(VCD) 2>NUL
