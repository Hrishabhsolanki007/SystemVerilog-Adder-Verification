quit -sim -force
vdel -all
vlib work

# Compile RTL
vlog -sv +cover RTL/*.sv

# Compile TB (ordered)
vlog -sv +cover TB/interface.sv
vlog -sv +cover TB/tb_pkg.sv
vlog -sv +cover TB/assertions.sv
vlog -sv +cover TB/tb.sv

# Run simulation with coverage
vsim -coverage work.tb

# Waves
log -r /*
add wave -r /*

# Assertions logging
set AssertionEnable 1
set AssertionLogEnable 1

# Run
run -all

# Reports
coverage report -details
assertion report -all