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


#include <stdio.h>
#include "xparameters.h"
#include "xenv_standalone.h"
#include "xintc.h"
//#include "intc_header.h"
#include "xbasic_types.h"
#include "xgpio.h"
#include "sleep.h"
#include "d_usb.h"
#include "xio.h"
#include "xil_cache.h"


#define USB_EPP_DATA_REG_OFFSET 0x00
#define USB_EPP_ADDRESS_REG_OFFSET 0x04
#define USB_EPP_STATUS_REG_OFFSET 0x08
#define USB_EPP_STATUS_READ_REQUESTED 0x80000000
#define USB_EPP_STATUS_WRITE_PERFORMED 0x40000000
#define USB_EPP_STATUS_TRANSACTION_PROCESSING 0x20000000

void USB_EPP_Reg_Write (Xuint32 USB_EPP_BASEADDR, Xuint32 ADDRESS, Xuint32 DATA){
	XIo_Out32(USB_EPP_BASEADDR + USB_EPP_ADDRESS_REG_OFFSET, ADDRESS);
	XIo_Out32(USB_EPP_BASEADDR + USB_EPP_DATA_REG_OFFSET, DATA);
}

Xuint32 USB_EPP_Reg_Read (Xuint32 USB_EPP_BASEADDR, Xuint32 ADDRESS){
	XIo_Out32(USB_EPP_BASEADDR + USB_EPP_ADDRESS_REG_OFFSET, ADDRESS);
	return XIo_In32(USB_EPP_BASEADDR + USB_EPP_DATA_REG_OFFSET);
}





int main() 
{

Xuint32 epp_data;
Xuint32 epp_address;
Xuint32 epp_status;
Xuint32 epp_control;

XStatus Status;

Xuint32 i = 0;

   static XIntc Intc;
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

   print("---Entering main---\n\r");

/*
   Status = XIntc_Initialize (&Intc, XPAR_XPS_INTC_0_DEVICE_ID);
   if (Status != XST_SUCCESS) xil_printf ("\r\nInterrupt controller initialization failure");
   else xil_printf("\r\nInterrupt controller initialized");
   
   Status = XIntc_Connect (&Intc, XPAR_XPS_INTC_0_USB_EPP_IF_0_EPP_IRPT_INTR,
                             (XInterruptHandler) usb_epp_interrupt_handler,
                             (void *)XPAR_USB_EPP_IF_0_BASEADDR);
  if (Status != XST_SUCCESS) xil_printf ("\r\nRegistering USB_EPP Interupt Failed");
  else xil_printf("\r\nUSB_EPP Interrupt registerred");

   XIntc_Enable  (&Intc, XPAR_XPS_INTC_0_USB_EPP_IF_0_EPP_IRPT_INTR); 
   
   
   Status = XIntc_Start(&Intc, XIN_REAL_MODE);
  if (Status != XST_SUCCESS) xil_printf ("\r\nInterupt controller starting failed");
  else xil_printf("\r\nInterrupt controller started");
  
  microblaze_enable_interrupts();
  
 
	while (1);
*/

	//reset EPP
	XIo_Out32 (D_USB_BASEADDR + EPP_CONTROL_REG_OFFSET, 1 << EPP_CONTROL_RESET_EPP);
	XIo_Out32 (D_USB_BASEADDR + EPP_CONTROL_REG_OFFSET, 0);

	


	for (i = 0; i < 256; i++)
	{
		XIo_Out32 (D_USB_BASEADDR + EPP_CONTROL_REG_OFFSET, ((1<<EPP_CONTROL_SEL_EXT_ADDR) | i));
		XIo_Out32 (D_USB_BASEADDR + EPP_DATA_REG_OFFSET, (255 - i));
		xil_printf("\r\nWriting to address 0x%X, data 0x%X", i, (255-i));
	}
	
	for (i = 0; i < 256; i++)
	{
		XIo_Out32 (D_USB_BASEADDR + EPP_CONTROL_REG_OFFSET, ((1<<EPP_CONTROL_SEL_EXT_ADDR) | i));
		epp_data = XIo_In32 (D_USB_BASEADDR + EPP_DATA_REG_OFFSET);
		xil_printf("\r\nReading from address 0x%X, data 0x%X", i, epp_data);
	}
		
		

	epp_status = XIo_In32(D_USB_BASEADDR + EPP_STATUS_REG_OFFSET);
	xil_printf("\r\nepp_status = 0x%X", epp_status);
	
	epp_control = XIo_In32(D_USB_BASEADDR + EPP_CONTROL_REG_OFFSET);
	epp_control = epp_control & (~(1 << EPP_CONTROL_SEL_EXT_ADDR));
	XIo_Out32 (D_USB_BASEADDR + EPP_CONTROL_REG_OFFSET, epp_control);

	while (1)
	{
		epp_status = XIo_In32(D_USB_BASEADDR + EPP_STATUS_REG_OFFSET);
		while (!(epp_status & (1 << EPP_STATUS_WRITE_PERFORMED)))
		{
			epp_status = XIo_In32(D_USB_BASEADDR + EPP_STATUS_REG_OFFSET);
			//xil_printf("\r\nepp_status = 0x%X", epp_status);
		}

		epp_address = epp_status & 0x000000FF;
		epp_data = XIo_In32(D_USB_BASEADDR + EPP_DATA_REG_OFFSET);
		
		xil_printf("\r\nDigilent USB write performed, Status = 0x%0.8X, Data = 0x%X", epp_status, epp_data); 

	}
	
   print("---Exiting main---\n\r");

   XCACHE_DISABLE_ICACHE();
   XCACHE_DISABLE_DCACHE();

   return 0;
}


