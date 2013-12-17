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
 * Xilinx EDK 11.4 EDK_LS4.68
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
 *    D:\Digilent\Projects\Atlys\Atlys_11_4_BSB\
 */


// Located in: microblaze_0/include/xparameters.h
#include "xparameters.h"

#include "stdio.h"

#include "xutil.h"
#include "xio.h"
#include "sleep.h"


//====================================================


int main (void) {

Xuint32 i, j;
Xuint32 Usb_epp_data;
Xuint32 Usb_epp_address;
Xuint32 Usb_epp_status;

Xuint8 Sw_Data, Led_Data, Btn_Data;

   /*
    * Enable and initialize cache
    */
   #if XPAR_MICROBLAZE_0_USE_ICACHE
      microblaze_invalidate_icache();
      microblaze_enable_icache();
   #endif

   #if XPAR_MICROBLAZE_0_USE_DCACHE
      microblaze_invalidate_dcache();
       microblaze_enable_dcache();
   #endif


   Xuint32 PS2_Status;
   Xuint32 PS2_Data=0;
   Xuint32 Chan_addr;
   XStatus Status;
   
   //check if channel_num

   print ("\r\nEntering Main");

	XIo_Out32 (XPAR_LEDS_8BITS_BASEADDR + 0x04, 0x00);
	
	XIo_Out32 (XPAR_LEDS_8BITS_BASEADDR, 0xFF);

	xil_printf("\r\nLEDs Set");

	//while (1);

   Chan_addr=0x0;
   
   //reset ps2_device 
   //XIo_Out32(XPAR_PS2_MOUSE_0_BASEADDR, 0x0A); 
	//XIo_Out32(XPAR_PS2_MOUSE_0_BASEADDR+0x1000, 0x0A); 
   //send reset to the PS2 device
   usleep (10000);
   //XIo_Out32(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x0C, 0xFF);
   usleep (10000);

/*	
	PS2_Status = XIo_In32(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x004);
   xil_printf ("\r\nPS2_Status = 0x%X", PS2_Status);
   while (1)
   {
     PS2_Status = XIo_In32(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x004);
     
     if ((PS2_Status&0x01)) //data was received
     {
      PS2_Data=XIo_In32(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x008);//read the data
		xil_printf("\r\nData received = 0x%X", PS2_Data);
     }
   }
*/	
	
	while (1)
	{
		Btn_Data = XIo_In32 (XPAR_PUSH_BUTTONS_5BITS_BASEADDR);
		//Sw_Data = XIo_In32 (XPAR_DIP_SWITCHES_8BITS_BASEADDR);
		//XIo_Out32 (XPAR_LEDS_8BITS_BASEADDR, Sw_Data);
		//if (Sw_Data) xil_printf ("\r\nSwitch Data = 0x%X", Sw_Data);
		
		//if (Btn_Data) xil_printf ("\r\nButton Data = 0x%X", Btn_Data);
		if (Btn_Data & 0x0A)
		{
			if (Btn_Data & 0x08) Chan_addr=0x0;
			else if (Btn_Data & 0x02) Chan_addr=0x1000;
			
			while (Btn_Data)//wait until the button is released, then send the data over PS2
			{
				Btn_Data = XIo_In32 (XPAR_PUSH_BUTTONS_5BITS_BASEADDR);						
			}
			
			Sw_Data = XIo_In32 (XPAR_DIP_SWITCHES_8BITS_BASEADDR);
			xil_printf ("\r\nSending to PS2 port channel %d, Data 0x%X", ((Chan_addr == 0x1000) ? 1:0), Sw_Data);
			XIo_Out32(XPAR_PS2_KEYBOARD_MOUSE_0_BASEADDR+Chan_addr+0x0C, Sw_Data);
			PS2_Status = XIo_In32(XPAR_PS2_KEYBOARD_MOUSE_0_BASEADDR+Chan_addr+0x004);
			while (PS2_Status&0x02)
			{
				PS2_Status = XIo_In32(XPAR_PS2_KEYBOARD_MOUSE_0_BASEADDR+Chan_addr+0x004);
			}
			xil_printf ("\r\nData Sent to PS2");
		}
		//check if data was received on Channel 1
		PS2_Status = XIo_In32(XPAR_PS2_KEYBOARD_MOUSE_0_BASEADDR+0x004);
		if ((PS2_Status&0x01)) //data was received
		{
			PS2_Data=XIo_In32(XPAR_PS2_KEYBOARD_MOUSE_0_BASEADDR+0x008);//read the data
			XIo_Out32 (XPAR_LEDS_8BITS_BASEADDR, PS2_Data);
			xil_printf("\r\nData received from PS2 Channel 1 = 0x%X", PS2_Data);
		}
		//Check if data was received on Channel 2
		PS2_Status = XIo_In32(XPAR_PS2_KEYBOARD_MOUSE_0_BASEADDR+0x1000+0x004);
		if ((PS2_Status&0x01)) //data was received
		{
			PS2_Data=XIo_In32(XPAR_PS2_KEYBOARD_MOUSE_0_BASEADDR+0x1000+0x008);//read the data
			XIo_Out32 (XPAR_LEDS_8BITS_BASEADDR, PS2_Data);
			xil_printf("\r\nData received from PS2 Channel 2 = 0x%X", PS2_Data);
		}
	}
		
		
	//usleep (10000);
   //check if the data was transmitted
/*
   PS2_Status = XIo_In8(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x004);
   while (PS2_Status&0x02)
	{
		PS2_Status = XIo_In8(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x004);
	}
	xil_printf("\r\nWaiting for acknowledge");
	while (!(PS2_Status&0x01))
	{
		PS2_Status = XIo_In8(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x004);
		//xil_printf("\r\nPS2_Status = 0x%X", PS2_Status);
	}
	PS2_Data=XIo_In32(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x008);//read the data
	xil_printf("\r\nData received = 0x%X", PS2_Data);
   

	XIo_Out32(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x0C, 0xED);
   PS2_Status = XIo_In8(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x004);
   while (PS2_Status&0x02)
	{
		PS2_Status = XIo_In8(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x004);
	}
	while (!(PS2_Status&0x01))
	{
		PS2_Status = XIo_In8(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x004);
	}
	PS2_Data=XIo_In32(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x008);//read the data
	xil_printf("\r\nData received = 0x%X", PS2_Data);
	
	XIo_Out32(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x0C, 0x05);
   //usleep (10000);
   //check if the data was transmitted
   PS2_Status = XIo_In8(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x004);
   while (PS2_Status&0x02)
	{
		PS2_Status = XIo_In8(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x004);
	}
	while (!(PS2_Status&0x01))
	{
		PS2_Status = XIo_In8(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x004);
	}
	PS2_Data=XIo_In32(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x008);//read the data
	xil_printf("\r\nData received = 0x%X", PS2_Data);
	
	//wait until data is sent

   i=0;
   while (i<10000)
   {
     PS2_Status = XIo_In32(XPAR_PS2_0_BASEADDR+Chan_addr+0x004);
     if (!(PS2_Status&0x02))  i=100000;
     i++;
     usleep (1);
   }
   usleep (100000);

   //check if data was received
   i=0;
   PS2_Status = XIo_In32(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x004);
   xil_printf ("\r\nPS2_Status = 0x%X", PS2_Status);
   while (1)
   {
     PS2_Status = XIo_In32(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x004);
     
     if ((PS2_Status&0x01)) //data was received
     {
      PS2_Data=XIo_In32(XPAR_PS2_MOUSE_0_BASEADDR+Chan_addr+0x008);//read the data
		xil_printf("\r\nData received = 0x%X", PS2_Data);
     }
   }
*/
}

