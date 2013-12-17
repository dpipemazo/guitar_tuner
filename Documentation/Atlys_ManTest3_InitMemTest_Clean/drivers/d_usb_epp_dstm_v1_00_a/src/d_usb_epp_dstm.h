/*****************************************************************************
* Filename:          D:\Digilent\Projects\Atlys\Atlys_12_2_RevC_BIST/drivers/d_usb_epp_dstm_v1_00_a/src/d_usb_epp_dstm.h
* Version:           1.00.a
* Description:       d_usb_epp_dstm Driver Header File
* Date:              Mon Sep 06 18:09:03 2010 (by Create and Import Peripheral Wizard)
*****************************************************************************/

#ifndef D_USB_EPP_DSTM_H
#define D_USB_EPP_DSTM_H

/***************************** Include Files *******************************/

#include "xbasic_types.h"
#include "xstatus.h"
#include "xio.h"

/************************** Constant Definitions ***************************/


/**
 * User Logic Slave Space Offsets
 * -- SLV_REG0 : user logic slave module register 0
 * -- SLV_REG1 : user logic slave module register 1
 * -- SLV_REG2 : user logic slave module register 2
 * -- SLV_REG3 : user logic slave module register 3
 * -- SLV_REG4 : user logic slave module register 4
 * -- SLV_REG5 : user logic slave module register 5
 * -- SLV_REG6 : user logic slave module register 6
 * -- SLV_REG7 : user logic slave module register 7
 * -- SLV_REG8 : user logic slave module register 8
 * -- SLV_REG9 : user logic slave module register 9
 * -- SLV_REG10 : user logic slave module register 10
 * -- SLV_REG11 : user logic slave module register 11
 */
#define D_USB_EPP_DSTM_USER_SLV_SPACE_OFFSET (0x00000000)
#define D_USB_EPP_DSTM_SLV_REG0_OFFSET (D_USB_EPP_DSTM_USER_SLV_SPACE_OFFSET + 0x00000000)
#define D_USB_EPP_DSTM_SLV_REG1_OFFSET (D_USB_EPP_DSTM_USER_SLV_SPACE_OFFSET + 0x00000004)
#define D_USB_EPP_DSTM_SLV_REG2_OFFSET (D_USB_EPP_DSTM_USER_SLV_SPACE_OFFSET + 0x00000008)
#define D_USB_EPP_DSTM_SLV_REG3_OFFSET (D_USB_EPP_DSTM_USER_SLV_SPACE_OFFSET + 0x0000000C)
#define D_USB_EPP_DSTM_SLV_REG4_OFFSET (D_USB_EPP_DSTM_USER_SLV_SPACE_OFFSET + 0x00000010)
#define D_USB_EPP_DSTM_SLV_REG5_OFFSET (D_USB_EPP_DSTM_USER_SLV_SPACE_OFFSET + 0x00000014)
#define D_USB_EPP_DSTM_SLV_REG6_OFFSET (D_USB_EPP_DSTM_USER_SLV_SPACE_OFFSET + 0x00000018)
#define D_USB_EPP_DSTM_SLV_REG7_OFFSET (D_USB_EPP_DSTM_USER_SLV_SPACE_OFFSET + 0x0000001C)
#define D_USB_EPP_DSTM_SLV_REG8_OFFSET (D_USB_EPP_DSTM_USER_SLV_SPACE_OFFSET + 0x00000020)
#define D_USB_EPP_DSTM_SLV_REG9_OFFSET (D_USB_EPP_DSTM_USER_SLV_SPACE_OFFSET + 0x00000024)
#define D_USB_EPP_DSTM_SLV_REG10_OFFSET (D_USB_EPP_DSTM_USER_SLV_SPACE_OFFSET + 0x00000028)
#define D_USB_EPP_DSTM_SLV_REG11_OFFSET (D_USB_EPP_DSTM_USER_SLV_SPACE_OFFSET + 0x0000002C)

/**************************** Type Definitions *****************************/


/***************** Macros (Inline Functions) Definitions *******************/

/**
 *
 * Write a value to a D_USB_EPP_DSTM register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the D_USB_EPP_DSTM device.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void D_USB_EPP_DSTM_mWriteReg(Xuint32 BaseAddress, unsigned RegOffset, Xuint32 Data)
 *
 */
#define D_USB_EPP_DSTM_mWriteReg(BaseAddress, RegOffset, Data) \
 	xil_io_out32((BaseAddress) + (RegOffset), (Xuint32)(Data))

/**
 *
 * Read a value from a D_USB_EPP_DSTM register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the D_USB_EPP_DSTM device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	Xuint32 D_USB_EPP_DSTM_mReadReg(Xuint32 BaseAddress, unsigned RegOffset)
 *
 */
#define D_USB_EPP_DSTM_mReadReg(BaseAddress, RegOffset) \
 	xil_io_in32((BaseAddress) + (RegOffset))


/**
 *
 * Write/Read 32 bit value to/from D_USB_EPP_DSTM user logic slave registers.
 *
 * @param   BaseAddress is the base address of the D_USB_EPP_DSTM device.
 * @param   RegOffset is the offset from the slave register to write to or read from.
 * @param   Value is the data written to the register.
 *
 * @return  Data is the data from the user logic slave register.
 *
 * @note
 * C-style signature:
 * 	void D_USB_EPP_DSTM_mWriteSlaveRegn(Xuint32 BaseAddress, unsigned RegOffset, Xuint32 Value)
 * 	Xuint32 D_USB_EPP_DSTM_mReadSlaveRegn(Xuint32 BaseAddress, unsigned RegOffset)
 *
 */
#define D_USB_EPP_DSTM_mWriteSlaveReg0(BaseAddress, RegOffset, Value) \
 	xil_io_out32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG0_OFFSET) + (RegOffset), (Xuint32)(Value))
#define D_USB_EPP_DSTM_mWriteSlaveReg1(BaseAddress, RegOffset, Value) \
 	xil_io_out32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG1_OFFSET) + (RegOffset), (Xuint32)(Value))
#define D_USB_EPP_DSTM_mWriteSlaveReg2(BaseAddress, RegOffset, Value) \
 	xil_io_out32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG2_OFFSET) + (RegOffset), (Xuint32)(Value))
#define D_USB_EPP_DSTM_mWriteSlaveReg3(BaseAddress, RegOffset, Value) \
 	xil_io_out32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG3_OFFSET) + (RegOffset), (Xuint32)(Value))
#define D_USB_EPP_DSTM_mWriteSlaveReg4(BaseAddress, RegOffset, Value) \
 	xil_io_out32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG4_OFFSET) + (RegOffset), (Xuint32)(Value))
#define D_USB_EPP_DSTM_mWriteSlaveReg5(BaseAddress, RegOffset, Value) \
 	xil_io_out32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG5_OFFSET) + (RegOffset), (Xuint32)(Value))
#define D_USB_EPP_DSTM_mWriteSlaveReg6(BaseAddress, RegOffset, Value) \
 	xil_io_out32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG6_OFFSET) + (RegOffset), (Xuint32)(Value))
#define D_USB_EPP_DSTM_mWriteSlaveReg7(BaseAddress, RegOffset, Value) \
 	xil_io_out32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG7_OFFSET) + (RegOffset), (Xuint32)(Value))
#define D_USB_EPP_DSTM_mWriteSlaveReg8(BaseAddress, RegOffset, Value) \
 	xil_io_out32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG8_OFFSET) + (RegOffset), (Xuint32)(Value))
#define D_USB_EPP_DSTM_mWriteSlaveReg9(BaseAddress, RegOffset, Value) \
 	xil_io_out32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG9_OFFSET) + (RegOffset), (Xuint32)(Value))
#define D_USB_EPP_DSTM_mWriteSlaveReg10(BaseAddress, RegOffset, Value) \
 	xil_io_out32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG10_OFFSET) + (RegOffset), (Xuint32)(Value))
#define D_USB_EPP_DSTM_mWriteSlaveReg11(BaseAddress, RegOffset, Value) \
 	xil_io_out32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG11_OFFSET) + (RegOffset), (Xuint32)(Value))

#define D_USB_EPP_DSTM_mReadSlaveReg0(BaseAddress, RegOffset) \
 	xil_io_in32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG0_OFFSET) + (RegOffset))
#define D_USB_EPP_DSTM_mReadSlaveReg1(BaseAddress, RegOffset) \
 	xil_io_in32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG1_OFFSET) + (RegOffset))
#define D_USB_EPP_DSTM_mReadSlaveReg2(BaseAddress, RegOffset) \
 	xil_io_in32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG2_OFFSET) + (RegOffset))
#define D_USB_EPP_DSTM_mReadSlaveReg3(BaseAddress, RegOffset) \
 	xil_io_in32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG3_OFFSET) + (RegOffset))
#define D_USB_EPP_DSTM_mReadSlaveReg4(BaseAddress, RegOffset) \
 	xil_io_in32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG4_OFFSET) + (RegOffset))
#define D_USB_EPP_DSTM_mReadSlaveReg5(BaseAddress, RegOffset) \
 	xil_io_in32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG5_OFFSET) + (RegOffset))
#define D_USB_EPP_DSTM_mReadSlaveReg6(BaseAddress, RegOffset) \
 	xil_io_in32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG6_OFFSET) + (RegOffset))
#define D_USB_EPP_DSTM_mReadSlaveReg7(BaseAddress, RegOffset) \
 	xil_io_in32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG7_OFFSET) + (RegOffset))
#define D_USB_EPP_DSTM_mReadSlaveReg8(BaseAddress, RegOffset) \
 	xil_io_in32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG8_OFFSET) + (RegOffset))
#define D_USB_EPP_DSTM_mReadSlaveReg9(BaseAddress, RegOffset) \
 	xil_io_in32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG9_OFFSET) + (RegOffset))
#define D_USB_EPP_DSTM_mReadSlaveReg10(BaseAddress, RegOffset) \
 	xil_io_in32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG10_OFFSET) + (RegOffset))
#define D_USB_EPP_DSTM_mReadSlaveReg11(BaseAddress, RegOffset) \
 	xil_io_in32((BaseAddress) + (D_USB_EPP_DSTM_SLV_REG11_OFFSET) + (RegOffset))

/************************** Function Prototypes ****************************/


/**
 *
 * Run a self-test on the driver/device. Note this may be a destructive test if
 * resets of the device are performed.
 *
 * If the hardware system is not built correctly, this function may never
 * return to the caller.
 *
 * @param   baseaddr_p is the base address of the D_USB_EPP_DSTM instance to be worked on.
 *
 * @return
 *
 *    - XST_SUCCESS   if all self-test code passed
 *    - XST_FAILURE   if any self-test code failed
 *
 * @note    Caching must be turned off for this function to work.
 * @note    Self test may fail if data memory and device are not on the same bus.
 *
 */
XStatus D_USB_EPP_DSTM_SelfTest(void * baseaddr_p);

#endif /** D_USB_EPP_DSTM_H */
