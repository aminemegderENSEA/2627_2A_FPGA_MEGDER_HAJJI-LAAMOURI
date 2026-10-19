# ModelSim / Questa - simulation fonctionnelle du telecran.
# Lancer depuis un dossier contenant telecran.vhd, telecran_tb.vhd et encoder.vhd.
# Les modeles PLL/I2C du testbench ne simulent pas l'IP reelle ni le signal HDMI analogique.
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vcom -2008 encoder.vhd
vcom -2008 telecran.vhd
vcom -2008 telecran_tb.vhd
vsim -voptargs=+acc work.telecran_tb
view wave
add wave -divider "Horloge et reset"
add wave sim:/telecran_tb/clk50
add wave sim:/telecran_tb/rst_n
add wave sim:/telecran_tb/dut/s_clk_27
add wave sim:/telecran_tb/dut/s_rst_n
add wave -divider "Encodeurs / coordonnees"
add wave sim:/telecran_tb/la
add wave sim:/telecran_tb/lb
add wave sim:/telecran_tb/lpb
add wave sim:/telecran_tb/ra
add wave sim:/telecran_tb/rb
add wave sim:/telecran_tb/rpb
add wave sim:/telecran_tb/dut/s_x
add wave sim:/telecran_tb/dut/s_y
add wave sim:/telecran_tb/dut/s_x_counter
add wave sim:/telecran_tb/dut/s_y_counter
add wave sim:/telecran_tb/dut/s_x_counter_d
add wave sim:/telecran_tb/dut/s_y_counter_d
add wave -divider "Sorties video"
add wave sim:/telecran_tb/hdmi_clk
add wave sim:/telecran_tb/hdmi_hs
add wave sim:/telecran_tb/hdmi_vs
add wave sim:/telecran_tb/hdmi_de
add wave sim:/telecran_tb/hdmi_d
add wave -divider "Checks"
add wave sim:/telecran_tb/saw_hs_low
add wave sim:/telecran_tb/saw_vs_low
add wave sim:/telecran_tb/saw_de
run 1.1 ms
wave zoom full
