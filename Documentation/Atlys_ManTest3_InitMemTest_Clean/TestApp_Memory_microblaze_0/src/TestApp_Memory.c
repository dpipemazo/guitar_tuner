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
 * Xilinx EDK 12.2 EDK_MS2.63c
 *
 * This file is a sample test application
 *
 * This application is intended to test and/or illustrate some 
 * functionality of your system.  The contents of this file may
 * vary depending on the IP in your system and may use existing
 * IP driver functions.  These drivers will be generated in your
 * XPS project when you run the "Generate Libraries" menu item
 * in XPS.
 *
 * Your XPS project directory is at:
 *    D:\Digilent\Projects\Atlys\Atlys_12_2_BSB_RevC\
 */

//#define Data_O_REG 					XPAR_SIGNAL_TESTER_0_BASEADDR
//#define Data_I_REG 					XPAR_SIGNAL_TESTER_0_BASEADDR + 0x4
//#define ADDRESS_REG 					XPAR_SIGNAL_TESTER_0_BASEADDR + 0x8
//#define SIGNAL_LOGIC_SQUARE_REG 	XPAR_SIGNAL_TESTER_0_BASEADDR + 0xC
//#define EXT_INT_REG 					XPAR_SIGNAL_TESTER_0_BASEADDR + 0x10
//#define INVERT_REG 					XPAR_SIGNAL_TESTER_0_BASEADDR + 0x14
//#define DIVRATE_REG 					XPAR_SIGNAL_TESTER_0_BASEADDR + 0x18
//#define FREQ_REG 						XPAR_SIGNAL_TESTER_0_BASEADDR + 0x1C
//#define GATE_DIV_REG 				XPAR_SIGNAL_TESTER_0_BASEADDR + 0x20
//#define COMPARE_VALUE_REG 			XPAR_SIGNAL_TESTER_0_BASEADDR + 0x24
//#define CTRL_REG 						XPAR_SIGNAL_TESTER_0_BASEADDR + 0x28
//#define STATUS_REG 					XPAR_SIGNAL_TESTER_0_BASEADDR + 0x2C
//
//#define STATUS_DONE					0
//#define STATUS_OVERFLOW				1
//
//#define CTRL_FSELECT						0
//#define CTRL_ASYNC						5
//#define CTRL_RESET_FREQUENCY_METER	6
//#define CTRL_EXT_INT						7


// Located in: microblaze_0/include/xparameters.h
#include "xparameters.h"

#include "xil_cache.h"
#include "xio.h"
#include "stdio.h"
#include "xuartns550.h"

#include "xil_testmem.h"
#include "xstatus.h"

//====================================================

int main (void) {

	Xuint32 Diff_Status;
	Xuint32 Diff_Ctrl;

	Xuint32 Freq_Value1, Freq_Value2;

   /*
    * Enable and initialize cache
    */
   #if XPAR_MICROBLAZE_0_USE_ICACHE
      Xil_ICacheInvalidate();
      Xil_ICacheEnable();
   #endif

   #if XPAR_MICROBLAZE_0_USE_DCACHE
      Xil_DCacheInvalidate();
       Xil_DCacheEnable();
   #endif

	
	XUartNs550_SetBaud(XPAR_UARTNS550_0_BASEADDR, XPAR_UARTNS550_0_CLOCK_FREQ_HZ, 9600);
   XUartNs550_SetLineControlReg(XPAR_UARTNS550_0_BASEADDR, XUN_LCR_8_DATA_BITS);


   print("-- Entering main() --\r\n");
/*
	//set signal type to 1 for the two outputs
	XIo_Out32(SIGNAL_LOGIC_SQUARE_REG, 0x03);
	//set division rate for divreg to obtain an about 10 KHz signal
	XIo_Out32(DIVRATE_REG, 2500);
	//set compare value for a duty cycle of 50%
	XIo_Out32(COMPARE_VALUE_REG, 1200);
	//set address value to write into RAM
	XIo_Out32(ADDRESS_REG, 0);
	
	//set division rate for divreg to obtain an about 10 KHz signal
	XIo_Out32(DIVRATE_REG, 3300);
	//set compare value for a duty cycle of 50%
	XIo_Out32(COMPARE_VALUE_REG, 1600);
	//set address value to write into RAM
	XIo_Out32(ADDRESS_REG, 1);

	//set the external clock
	//Diff_Ctrl = XIo_In32(CTRL_REG);
	//XIo_Out32 (CTRL_REG, Diff_Ctrl | (1 << CTRL_EXT_INT));
	
	//set the gate to be about 100 ms
	XIo_Out32(GATE_DIV_REG, 0x65B9AA);
	
	Diff_Status = XIo_In32(STATUS_REG);
	xil_printf("\r\nDiff status = 0x%X", Diff_Status);
	

	xil_printf("\r\nSignals set");

	while(1)
	{
		//select first channel to measure frequency and reset the frequency meter
		Diff_Ctrl = XIo_In32(CTRL_REG);
		Diff_Ctrl = (Diff_Ctrl & (~ (0x1F << CTRL_FSELECT))) | (0 << CTRL_FSELECT) | (1 << CTRL_ASYNC) | (1 << CTRL_RESET_FREQUENCY_METER);
		XIo_Out32(CTRL_REG, Diff_Ctrl);
		xil_printf("\r\nDiff_Ctrl for the first channel is 0x%X", Diff_Ctrl); 
		
		Diff_Status = XIo_In32(STATUS_REG);
		xil_printf("\r\nDiff_Status after setting the first channel is 0x%X", Diff_Status); 
		//Start the frequency meter
		Diff_Ctrl = XIo_In32(CTRL_REG);
		Diff_Ctrl = (Diff_Ctrl & (~ (1 << CTRL_RESET_FREQUENCY_METER)));
		XIo_Out32(CTRL_REG, Diff_Ctrl);
		
		Diff_Ctrl = XIo_In32(CTRL_REG);
		xil_printf("\r\nDiff_Ctrl after starting the frequency meter is 0x%X", Diff_Ctrl); 
		
		Diff_Status = XIo_In32(STATUS_REG);
		while (!(XIo_In32(STATUS_REG) & (1 << STATUS_DONE)));
		
		Diff_Status = XIo_In32(STATUS_REG);
		xil_printf("\r\nDiff status 1 = 0x%X", Diff_Status);
		
		Freq_Value1 = XIo_In32 (FREQ_REG);
		
		//select second channel to measure frequency and reset the frequency meter
		Diff_Ctrl = XIo_In32(CTRL_REG);
		Diff_Ctrl = (Diff_Ctrl & (~ (0x1F << CTRL_FSELECT))) | (1 << CTRL_FSELECT) | (1 << CTRL_ASYNC) | (1 << CTRL_RESET_FREQUENCY_METER);
		XIo_Out32(CTRL_REG, Diff_Ctrl);
		xil_printf("\r\nDiff_Ctrl for the second channel is 0x%X", Diff_Ctrl); 
		
		Diff_Status = XIo_In32(STATUS_REG);
		xil_printf("\r\nDiff_Status after setting the second channel is 0x%X", Diff_Status); 
		//Start the frequency meter
		Diff_Ctrl = XIo_In32(CTRL_REG);
		Diff_Ctrl = (Diff_Ctrl & (~ (1 << CTRL_RESET_FREQUENCY_METER)));
		XIo_Out32(CTRL_REG, Diff_Ctrl);
		
		Diff_Status = XIo_In32(STATUS_REG);
		while (!(XIo_In32(STATUS_REG) & (1 << STATUS_DONE)));
		
		Diff_Status = XIo_In32(STATUS_REG);
		xil_printf("\r\nDiff status 2 = 0x%X", Diff_Status);
		
		Freq_Value2 = XIo_In32 (FREQ_REG);

		xil_printf ("\r\nMeasured frequency value on channel 1 = %d, channel 2 = %d", Freq_Value1, Freq_Value2);
		
	
	}


	while (1);

*/






   /* Testing MPMC Memory (MCB_DDR2)*/
   {
      XStatus status;

      print("Starting MemoryTest for MCB_DDR2:\r\n");
      print("  Running 32-bit test...");
      status = Xil_TestMem32((u32*)XPAR_MCB_DDR2_MPMC_BASEADDR, 1024, 0xAAAA5555, XIL_TESTMEM_ALLMEMTESTS);
      if (status == XST_SUCCESS) {
         print("PASSED!\r\n");
      }
      else {
         print("FAILED!\r\n");
      }
      print("  Running 16-bit test...");
      status = Xil_TestMem16((u16*)XPAR_MCB_DDR2_MPMC_BASEADDR, 2048, 0xAA55, XIL_TESTMEM_ALLMEMTESTS);
      if (status == XST_SUCCESS) {
         print("PASSED!\r\n");
      }
      else {
         print("FAILED!\r\n");
      }
      print("  Running 8-bit test...");
      status = Xil_TestMem8((u8*)XPAR_MCB_DDR2_MPMC_BASEADDR, 4096, 0xA5, XIL_TESTMEM_ALLMEMTESTS);
      if (status == XST_SUCCESS) {
         print("PASSED!\r\n");
      }
      else {
         print("FAILED!\r\n");
      }
   }

   /**
    * MpmcSelfTestExample() will not be run for the memory 
    * (MCB_DDR2) because ECC is not supported.
    */


   /* 
    * MemoryTest routine will not be run for the memory at 
    * 0x00000000 (dlmb_cntlr)
    * because it is being used to hold a part of this application program
    */

   /*
    * Disable cache and reinitialize it so that other
    * applications can be run with no problems
    */
   #if XPAR_MICROBLAZE_0_USE_DCACHE
      Xil_DCacheDisable();
      Xil_DCacheInvalidate();
   #endif

   #if XPAR_MICROBLAZE_0_USE_ICACHE
      Xil_ICacheDisable();
      Xil_ICacheInvalidate();
   #endif


   print("-- Exiting main() --\r\n");
   return 0;
}

