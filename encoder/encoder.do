# ModelSim / Questa. Lancer ce script depuis le dossier encoder.
# La simulation est limitee dans le temps pour eviter run -all infini.
if {[file exists work]} {vdel -lib work -all}
vlib work
vmap work work
vcom -2008 encoder.vhd
vcom -2008 encoder_tb.vhd
vsim -voptargs=+acc work.encoder_tb
view wave
add wave -divider "Horloge et reset"
add wave sim:/encoder_tb/clk
add wave sim:/encoder_tb/rst_n
add wave -divider "Entrees encodeur"
add wave sim:/encoder_tb/ch_a
add wave sim:/encoder_tb/ch_b
add wave sim:/encoder_tb/pb
add wave -divider "Sortie"
add wave sim:/encoder_tb/count
run 5 us
wave zoom full
