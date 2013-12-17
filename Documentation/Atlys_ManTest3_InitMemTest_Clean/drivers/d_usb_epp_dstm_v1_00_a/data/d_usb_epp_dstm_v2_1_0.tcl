##############################################################################
## Filename:          D:\Digilent\Projects\Atlys\Atlys_12_2_RevC_BIST/drivers/d_usb_epp_dstm_v1_00_a/data/d_usb_epp_dstm_v2_1_0.tcl
## Description:       Microprocess Driver Command (tcl)
## Date:              Mon Sep 06 18:09:03 2010 (by Create and Import Peripheral Wizard)
##############################################################################

#uses "xillib.tcl"

proc generate {drv_handle} {
  xdefine_include_file $drv_handle "xparameters.h" "d_usb_epp_dstm" "NUM_INSTANCES" "DEVICE_ID" "C_BASEADDR" "C_HIGHADDR" 
}
