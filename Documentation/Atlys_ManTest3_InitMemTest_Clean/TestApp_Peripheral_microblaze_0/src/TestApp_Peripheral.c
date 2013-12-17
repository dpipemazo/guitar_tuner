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


// Located in: microblaze_0/include/xparameters.h
#include "xparameters.h"

#include "xil_cache.h"

#include "stdio.h"

#include "xintc.h"
#include "intc_header.h"
#include "xbasic_types.h"
#include "xgpio.h"
#include "gpio_header.h"
#include "xspi.h"
#include "spi_header.h"
#include "xlltemac.h"
#include "xlltemac_example.h"
#include "lltemac_header.h"
#include "lltemac_intr_header.h"
#include "xlldma.h"
#include "uartlite_header.h"

//====================================================

int main (void) {


   static XIntc intc;

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

   static XLlTemac Soft_TEMAC_LlTemac;
   static XLlDma  Soft_TEMAC_LlDma;


   print("-- Entering main() --\r\n");


   {
      int status;
      
      print("\r\n Running IntcSelfTestExample() for xps_intc_0...\r\n");
      
      status = IntcSelfTestExample(XPAR_XPS_INTC_0_DEVICE_ID);
      
      if (status == 0) {
         print("IntcSelfTestExample PASSED\r\n");
      }
      else {
         print("IntcSelfTestExample FAILED\r\n");
      }
   } 
	
   {
       int Status;

       Status = IntcInterruptSetup(&intc, XPAR_XPS_INTC_0_DEVICE_ID);
       if (Status == 0) {
          print("Intc Interrupt Setup PASSED\r\n");
       } 
       else {
         print("Intc Interrupt Setup FAILED\r\n");
      } 
   }

   /*
    * Peripheral SelfTest will not be run for RS232_Uart_1
    * because it has been selected as the STDOUT device
    */



   {
      u32 status;
      
      print("\r\nRunning GpioInputExample() for DIP_Switches_8Bits...\r\n");

      u32 DataRead;
      
      status = GpioInputExample(XPAR_DIP_SWITCHES_8BITS_DEVICE_ID, &DataRead);
      
      if (status == 0) {
         xil_printf("GpioInputExample PASSED. Read data:0x%X\r\n", DataRead);
      }
      else {
         print("GpioInputExample FAILED.\r\n");
      }
   }


   {
      u32 status;
      
      print("\r\nRunning GpioOutputExample() for LEDs_8Bits...\r\n");

      status = GpioOutputExample(XPAR_LEDS_8BITS_DEVICE_ID,8);
      
      if (status == 0) {
         print("GpioOutputExample PASSED.\r\n");
      }
      else {
         print("GpioOutputExample FAILED.\r\n");
      }
   }


   {
      u32 status;
      
      print("\r\nRunning GpioInputExample() for Push_Buttons_5Bits...\r\n");

      u32 DataRead;
      
      status = GpioInputExample(XPAR_PUSH_BUTTONS_5BITS_DEVICE_ID, &DataRead);
      
      if (status == 0) {
         xil_printf("GpioInputExample PASSED. Read data:0x%X\r\n", DataRead);
      }
      else {
         print("GpioInputExample FAILED.\r\n");
      }
   }


   {
      XStatus status;
      
      print("\r\n Runnning SpiSelfTestExample() for SPI_FLASH...\r\n");
      
      status = SpiSelfTestExample(XPAR_SPI_FLASH_DEVICE_ID);
      
      if (status == 0) {
         print("SpiSelfTestExample PASSED\r\n");
      }
      else {
         print("SpiSelfTestExample FAILED\r\n");
      }
   }

   /* TemacPolledExample does not support SGDMA      
   {
      XStatus status;

      print("\r\n Running TemacPolledExample() for Soft_TEMAC...\r\n");

      status = TemacPolledExample( XPAR_SOFT_TEMAC_CHAN_0_DEVICE_ID,
                                   );

      if (status == 0) {
         print("TemacPolledExample PASSED\r\n");
      }
      else {
         print("TemacPolledExample FAILED\r\n");
      }

   }
   */

   {
      XStatus Status;

      print("\r\nRunning TemacSgDmaIntrExample() for Soft_TEMAC...\r\n");

      Status = TemacSgDmaIntrExample(&intc, &Soft_TEMAC_LlTemac,
                     &Soft_TEMAC_LlDma,
                     XPAR_SOFT_TEMAC_CHAN_0_DEVICE_ID,
                     XPAR_XPS_INTC_0_SOFT_TEMAC_TEMACINTC0_IRPT_INTR,
                     XPAR_LLTEMAC_0_LLINK_CONNECTED_DMARX_INTR,
                     XPAR_LLTEMAC_0_LLINK_CONNECTED_DMATX_INTR);

      if (Status == 0) {
         print("Temac Interrupt Test PASSED.\r\n");
      } 
      else {
         print("Temac Interrupt Test FAILED.\r\n");
      }

   }


   {
      int status;
      
      print("\r\nRunning UartLiteSelfTestExample() for mdm_0...\r\n");
      status = UartLiteSelfTestExample(XPAR_MDM_0_DEVICE_ID);
      if (status == 0) {
         print("UartLiteSelfTestExample PASSED\r\n");
      }
      else {
         print("UartLiteSelfTestExample FAILED\r\n");
      }
   }
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

