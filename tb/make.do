transcript on


vlib work

vlog -sv ../src/traffic_lights.sv
vlog -sv ./traffic_lights_tb.sv

vsim -novopt traffic_lights_tb 

add wave /traffic_lights_tb/clk
add wave /traffic_lights_tb/rst
add wave /traffic_lights_tb/cmd_valid_i
add wave /traffic_lights_tb/cmd_type_i
add wave /traffic_lights_tb/cmd_data_i
add wave /traffic_lights_tb/red_o
add wave /traffic_lights_tb/yellow_o
add wave /traffic_lights_tb/green_o
add wave /traffic_lights_tb/DUT/wrk_en



run -all

