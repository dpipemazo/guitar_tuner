/*
 *
 * Xilinx, Inc.
 * XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
 * COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
 * ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
 * STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
 * IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
 * FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION
 * XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
 * THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
 * ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
 * FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE.
 */

/*
 * 
 *
 * This file is a generated sample test application.
 *
 * This application is intended to test and/or illustrate some 
 * functionality of your system.  The contents of this file may
 * vary depending on the IP in your system and may use existing
 * IP driver functions.  These drivers will be generated in your
 * SDK application project when you run the "Generate Libraries" menu item.
 *
 */



#define D_USB_EPP_SWITCH_REG 	0x10
#define D_USB_EPP_BUTTON_REG 	0x11
#define D_USB_EPP_COMMAND_REG 	0x80
#define D_USB_EPP_STATUS_REG 	0x81
#define D_USB_EPP_RESULT_REG 	0x82
#define D_USB_EPP_ERROR_REG_0 	0x83
#define D_USB_EPP_ERROR_REG_1 	0x84
#define D_USB_EPP_ERROR_REG_2 	0x85
#define D_USB_EPP_ERROR_REG_3 	0x86

#define FLASH_ADDRESS_REG_0 	0x87
#define FLASH_ADDRESS_REG_1 	0x88
#define FLASH_ADDRESS_REG_2 	0x89

#define DATA_SIZE_REG_0 		0x90
#define DATA_SIZE_REG_1 		0x91
#define DATA_SIZE_REG_2 		0x92
#define DATA_SIZE_REG_3 		0x93

#define DATA_RECEIVE_REG 		0xA0

#define STATUS_TEST_RUNNING 			0xFF
#define STATUS_BIST_STARTED_IDLE 		0x01
#define STATUS_COMMAND_RECEIVED 		0x02
#define STATUS_UNRECOGNIZED_COMMAND		0x0F
#define STATUS_DATA_RECEIVE_MODE 		0x03
#define STATUS_DATA_SEND_MODE 			0x04
#define STATUS_BIST_NOT_STARTED_IDLE 	0x00

#define STATUS_TEST_FAILED 		0x01
#define STATUS_TEST_PASSED		0x00

/**************************************************************************************************
 *  Function prototypes                                                                           *
 *************************************************************************************************/

Xuint32 Erase_Sector (Xuint32 QuadSPI_Baseaddr, Xuint32 ADDRESS);
Xuint32 Blank_Check_Sector (Xuint32 QuadSPI_Baseaddr, Xuint32 ADDRESS);
Xuint32 Erase_Entire_Memory (Xuint32 QuadSPI_Baseaddr);
Xuint32 Blank_Check_Entire_Memory (Xuint32 QuadSPI_Baseaddr);
Xuint32 Quad_SPI_Flash_Test (Xuint32 QuadSPI_Baseaddr);
Xuint32 Check_Initial_Mode (Xuint32 QuadSPI_Baseaddr);
Xuint32 Manufact_ID (Xuint32 QuadSPI_Baseaddr);
Xuint32 Check_Initial_Mode (Xuint32 QuadSPI_Baseaddr);
Xuint32 Fast_Read (Xuint32 QuadSPI_Baseaddr, Xuint32 DIV_RATE, Xuint32 CURRENT_MODE, Xuint32 MODE,
		Xuint32 ADDRESS, Xuint32 NR_OF_BYTES, Xuint32 NR_OF_DUMMY_CLKS, u8 DATA[256]);
Xuint32 Page_Program (Xuint32 QuadSPI_Baseaddr, Xuint32 DIV_RATE, Xuint32 CURRENT_MODE, Xuint32 MODE,
		Xuint32 ADDRESS, Xuint32 NR_OF_BYTES, u8 DATA[256]);

Xuint32 memory_test (unsigned int MEM_BASEADDR, unsigned int MEM_HIGHADDR, unsigned int DATA_WIDTH);

Xuint32 I2C_Short_Test(XGpio I2C_Bus);
Xuint32 I2C_Loopback_Test_1(XGpio I2C_Bus);
Xuint32 I2C_Loopback_Test_2(XGpio I2C_Bus);

/*************************************************************************************************/

