setMode -bscan
setCable -p auto
#setCable -target "digilent_plugin"
identify
assignfile -p 1 -file implementation/download.bit
program -p 1
quit
