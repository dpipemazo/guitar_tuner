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
 * Xilinx EDK 10.1.02 EDK_K_SP2.5
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
 *    D:\Home\Albert\Digilent\Projects\Xupv5\ML505_bsb_project\
 */


// Located in: microblaze_0/include/xparameters.h
#include "xparameters.h"

#include "stdio.h"
#include "xio.h"
#include "xuartns550_l.h"
#include "xutil.h"
#include "xgpio.h"
#include "xio.h"
#include "sleep.h"
#include "xbasic_types.h"


extern unsigned char verbose;


Xuint32 memory_test (unsigned int MEM_BASEADDR, unsigned int MEM_HIGHADDR, 
                          unsigned int DATA_WIDTH)
{

Xuint32 MEM_SIZE; //determines the memory size
Xuint32 ADDRESS_LINES; //determines the address lines needed to walk
Xuint32 i;
Xuint32 MEM_ADDR;
Xuint8 MEM_DATA_8_WR;//, MEM_DATA_8_RD;
Xuint32 MEM_DATA_WR, MEM_DATA_RD;
Xuint32 err=0;

Xuint32 Failed_Address = 0;

MEM_SIZE=MEM_HIGHADDR-MEM_BASEADDR+1;

ADDRESS_LINES=0;
MEM_ADDR=1;
while (MEM_ADDR<MEM_SIZE)
{
   MEM_ADDR = 1 << ADDRESS_LINES;
   ADDRESS_LINES++;
}

ADDRESS_LINES--; //decrement with one to obtain 
                 //the correct number of address lines

 if (verbose) xil_printf("\r\nMemory size = 0x%X, ADDRESS LINES = 0x%X", MEM_SIZE, ADDRESS_LINES);


//walk 1 test

//memory write
//check the least significant two address lines first
//the data written to the memory will be 0x01020408
for (i=0; i<4; i++)
{
      MEM_ADDR = MEM_BASEADDR + i;
      MEM_DATA_8_WR = 1 << i;
      XIo_Out8(MEM_ADDR, MEM_DATA_8_WR);
      if (verbose) xil_printf("\r\nWriting 8-bit to Address 0x%08.8X, Data 0x%08.8X", MEM_ADDR, MEM_DATA_8_WR);
}


//walk 1 on the rest of the address lines
for (i=2 ; i<=(ADDRESS_LINES-1); i=i+1)
	{
      MEM_ADDR = MEM_BASEADDR + (1<<i);
      MEM_DATA_WR = 1 <<(i+2);
      XIo_Out32(MEM_ADDR, MEM_DATA_WR);
      if (verbose) xil_printf("\r\nWriting to Address 0x%08.8X, Data 0x%08.8X", MEM_ADDR, MEM_DATA_WR);
	}
//walk 1 on the rest of the data lines
for (i=0; i<=(31-ADDRESS_LINES-2); i=i+1)
   {
      MEM_ADDR = MEM_BASEADDR + (0xF<<(ADDRESS_LINES-4)) + (i * 4);
      MEM_DATA_WR = 1 << (i+ADDRESS_LINES+2);
      XIo_Out32 (MEM_ADDR, MEM_DATA_WR);
      if (verbose) xil_printf("\r\nWriting to Address 0x%08.8X, Data 0x%08.8X", MEM_ADDR, MEM_DATA_WR);
   }

//write 0 to the highest address
XIo_Out32(MEM_HIGHADDR-3, 0x0);
if (verbose) xil_printf("\r\nWriting to Address 0x%08.8X, Data 0x00000000", MEM_HIGHADDR-3);

//write 0xFFFFFFFF to the previous location
XIo_Out32(MEM_HIGHADDR-7, 0xFFFFFFFF);
 if (verbose) xil_printf("\r\nWriting to Address 0x%08.8X, Data 0xFFFFFFFF", MEM_HIGHADDR-7);


//memory read

//check the least significant two address lines first
//the data written to the memory will be 0x01020408
MEM_DATA_RD=XIo_In32(MEM_BASEADDR);
if (verbose) xil_printf("\r\nReading form Address 0x%08.8X, Data 0x%08.8X", MEM_BASEADDR, MEM_DATA_RD);
if (!(MEM_DATA_RD==0x01020408))
{
   err++;
   Failed_Address = 0XFFFFFFFE;
   return Failed_Address;
   if (verbose) xil_printf("\r\nMemory Error at Address 0, Expected 0x01020408, got 0x%08.8X", MEM_DATA_RD);
}

//check the walk 1 on the rest of the address lines
for (i=2 ; i<=(ADDRESS_LINES-1); i=i+1)
	{
      MEM_ADDR = MEM_BASEADDR + (1<<i);
      MEM_DATA_RD = XIo_In32(MEM_ADDR);
      MEM_DATA_WR = 1 <<(i+2);
      if (verbose) xil_printf("\r\nReading form Address 0x%08.8X, Data 0x%08.8X", MEM_ADDR, MEM_DATA_RD);
      if (!(MEM_DATA_RD==MEM_DATA_WR))
      {
         err++;
         if (!(Failed_Address)) Failed_Address = MEM_ADDR;
         return Failed_Address;
         if (verbose) xil_printf("\r\nMemory Error at Address 0x%08.8X, Expected 0x%08.8X, got 0x%08.8X", MEM_ADDR, MEM_DATA_WR, MEM_DATA_RD);
      }
	}

//check the walk 1 on the rest of the data lines
for (i=0; i<=(31-ADDRESS_LINES-2); i=i+1)
   {
      MEM_ADDR = MEM_BASEADDR + (0xF<<(ADDRESS_LINES-4)) + (i * 4);
      MEM_DATA_RD = XIo_In32(MEM_ADDR);
      MEM_DATA_WR = 1 << (i+ADDRESS_LINES+2);
      if (verbose) xil_printf("\r\nReading form Address 0x%08.8X, Data 0x%08.8X", MEM_ADDR, MEM_DATA_RD);
      if (!(MEM_DATA_RD==MEM_DATA_WR))
      {
         err++;
         if (!(Failed_Address)) Failed_Address = MEM_ADDR;
         return Failed_Address;
         if (verbose) xil_printf("\r\nMemory Error at Address 0x%08.8X, Expected 0x%08.8X, got 0x%08.8X", MEM_ADDR, MEM_DATA_WR, MEM_DATA_RD);
      }
   }

//check if 0x00000000 and 0xFFFFFFFF are read correctly
MEM_DATA_RD=XIo_In32(MEM_HIGHADDR-3);
if (verbose) xil_printf("\r\nReading form Address 0x%08.8X, Data 0x%08.8X", MEM_HIGHADDR-3, MEM_DATA_RD);
if (!(MEM_DATA_RD==0x0))
{
   if (!(Failed_Address)) Failed_Address = MEM_ADDR;
   return Failed_Address;
   err++;
   if (verbose) xil_printf("\r\nMemory Error at Address 0x%08.8X, Expected 0x00000000, got 0x%08.8X", MEM_HIGHADDR-3, MEM_DATA_RD);
}

MEM_DATA_RD=XIo_In32(MEM_HIGHADDR-7);
if (verbose) xil_printf("\r\nReading form Address 0x%08.8X, Data 0x%08.8X", MEM_HIGHADDR-7, MEM_DATA_RD);
if (!(MEM_DATA_RD==0xFFFFFFFF))
{
   if (!(Failed_Address)) Failed_Address = MEM_ADDR;
   return Failed_Address;
   err++;
if (verbose)  xil_printf("\r\nMemory Error at Address 0x%08.8X, Expected 0xFFFFFFFF, got 0x%08.8X", MEM_HIGHADDR-7, MEM_DATA_RD);
}

return Failed_Address;
}



