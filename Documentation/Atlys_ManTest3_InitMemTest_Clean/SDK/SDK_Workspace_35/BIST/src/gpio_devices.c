
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

//#include "xuartns550_l.h"
//#include "xutil.h"
#include "xgpio.h"
#include "xgpio_l.h"
#include "xio.h"
#include "sleep.h"
#include "xbasic_types.h"
//#include "xlltemac.h"
//#include "ac97_if_00.h"

#define LED_NORMAL  0x0
#define LED_ON      0x3
#define LED_OFF     0x2
#define LED_BLINK   0x1


//====================================================

//extern unsigned char dip, dip_pre; //used to determine the status of the DIP switches
//extern unsigned char push, push_pre; //used to determine the status of the pushbuttons
                               //bit 0 - center button
                               //bit 1 - left button
                               //bit 2 - down button
                               //bit 3 - right button
                               //bit 4 - up button
                               //bit 5 - BTN1 button
                               //bit 6 - BTN0 button

//extern unsigned char gpio_devices[13]; //shows the status of the GPIO devices,
//0 - unchanged, 1 - pressed or on, 2 - released or off
//0 to 7 - DIP switches, 8-14 - push buttons

//extern XLlTemac Hard_Ethernet_MAC_LlTemac;
//extern int PhyAddr;

extern XGpio LED8;
extern XGpio I2C_Bus;
XStatus Status;

extern unsigned char verbose;

//====================================================


void Gpio_devices_initialize()
{

	Status = XGpio_Initialize(&I2C_Bus, XPAR_I2C_BUS_DEVICE_ID );
	Status = XGpio_Initialize(&LED8, XPAR_LEDS_8BITS_DEVICE_ID);

	XGpio_SetDataDirection(&LED8, 1, 0x0);

	//dip = XGpio_DiscreteRead(&DIP8, 1);

	//dip_pre=dip;

	//push = XGpio_DiscreteRead(&Push5, 1);
	//push_pre=push;

	//XGpio_DiscreteWrite(&LED8, 1, dip);

}



/************************************************************************************************************************************
 *  		I2C Bus Short Test
 *
 * 	Bit 0  -----> JA-SCL (MSB)
 *	Pin 1  -----> JA-SDA
 *	Pin 2  -----> TMDS-TX-SCL
 *	Pin 3  -----> TMDS-TX-SDA
 *	Pin 4  -----> TMDS-RX-SCL
 *	Pin 5  -----> TMDS-RX-SDA
 *
 *
 ***********************************************************************************************************************************/

Xuint32 I2C_Short_Test(XGpio I2C_Bus)
{


	Xuint32 Write_Data;
	Xuint32 Read_Data;
	Xuint32 i;
	Xuint32 err1,err2,err;
	Xuint32 Error_Code;

	err1 = 0;
	err2 = 0;
	err  = 0;
	Error_Code = 0;

	// test if any pin is shorted to VCC

	if (verbose) xil_printf("\r\nTest if any pin is shorted to VCC ...");
	Write_Data = 0x00000000;

	XGpio_SetDataDirection (&I2C_Bus, 1 , Write_Data);

	XGpio_DiscreteWrite(&I2C_Bus, 1, Write_Data);

	Write_Data = Write_Data & 0x0000003F;

	if (verbose) xil_printf ("\r\nWriting to connector 0x%02.2X", Write_Data);

	usleep(100);
	Read_Data = XGpio_DiscreteRead(&I2C_Bus, 1);

	Read_Data = Read_Data & 0x0000003F;

	if(verbose) xil_printf("\r\nReading from connector 0x%02.2X", Read_Data);

	for(i=0;i<6;i++)
	{
		if (!(Read_Data == Write_Data))
		{
			err1++;
			Error_Code = i;
			if (verbose) xil_printf ("\r\nError : pin shorted to VCC . Expected 0x%02.2X, got 0x%02.2X, bit number : %d , "
					"number of errors %d", Write_Data, Read_Data, i , err  );
			if (verbose) xil_printf ("\r\nError_Code = ", Error_Code);
		}
	}
			if (!err1)
				if (verbose) xil_printf("\r\nVCC Test passed ...\n\n");

	// test if any pin is shorted to GND
	if (verbose) xil_printf("\r\nTest if any pin is shorted to GND ...");

	Write_Data = 0xFFFFFFFF;

	XGpio_SetDataDirection(&I2C_Bus, 1, Write_Data);

	XGpio_DiscreteWrite(&I2C_Bus, 1 , Write_Data);

	Write_Data = Write_Data & 0x0000003F;

	if (verbose) xil_printf("\r\nWriting to connector 0x%02.2X", Write_Data);

	usleep(100);

	Read_Data = XGpio_DiscreteRead(&I2C_Bus, 1);

	Read_Data = Read_Data & 0x0000003F;

	if (verbose) xil_printf("\r\nReading from connector 0x%02.2X", Read_Data);

	for (i=0;i<6;i++)
	{
		if (!(Read_Data == Write_Data))
		{
			err2++;
			Error_Code = i;

			if (verbose) xil_printf("\r\nError : pin shorted to ground, expected 0x%02.2X, got 0x%02.2X, bit number %d, "
					"number of errors : %d", Write_Data, Read_Data , i, err);
			if (verbose) xil_printf("\r\nError Code : %X", Error_Code);
		}
	}
	if (!err2)
				if (verbose)  xil_printf("\r\nGND Test passed ...\n\n");

	// walk 0 on all I2C pins

	Write_Data = 0xFFFFFFFF;

	for (i=0;i<6;i++)
	{

		Write_Data = 0xFFFFFFFF & (~(1 << i));

		XGpio_SetDataDirection(&I2C_Bus, 1 , Write_Data);

		XGpio_DiscreteWrite(&I2C_Bus, 1, Write_Data);

		Write_Data = Write_Data & 0x0000003F;

		if(verbose) xil_printf("\r\nWriting to connector 0x%02.2X", Write_Data);

		usleep(100);

		Read_Data = XGpio_DiscreteRead(&I2C_Bus, 1 );

		Read_Data = Read_Data & 0x0000003F;

		if (verbose) xil_printf("\r\nReading from connector 0x%02.2X", Read_Data);



		if (!(Read_Data == Write_Data))
		{
			err++;
			Error_Code = 5-i;
			if (verbose) xil_printf("\r\nError, expected 0x%02.2X, got 0x%02.2X, pin number %d", Write_Data, Read_Data, (5-i));
			if (verbose) xil_printf("\r\nError Code : 0x%02.2X", Error_Code);
		}
	}



	if (!(err))
		return XTEST_PASSED;
	else
		return Error_Code;
}



/***********************************************************************************************************************************
	Loopback test between J1 and J2 Connectors
		//Pin 0  -----> J1-SCL (MSB)
		//Pin 1  -----> J1-SDA
		//Pin 2  -----> TMDS-TX-SCL
		//Pin 3  -----> TMDS-TX-SDA

	Walk 0 on J1-SCL, Read from TMDS-TX-SCL
	Walk 0 on J1-SDA, Read from TMDS-TX-SDA

	In order to test HDMI connectors, plug a HDMI-A cable into J1 and J2 connectors, and place jumpers on JP2 connector
************************************************************************************************************************************/
Xuint32 I2C_Loopback_Test_1(XGpio I2C_Bus)
{
	Xuint32 Write_Data;
	Xuint32 Read_Data;

	Xuint32 i;
	Xuint32 err;
	Xuint32 Error_Code;

	err = 0;
	Error_Code = 0;

	Write_Data = 0xFFFFFFFF;


	// walk 0 on J1-SCL, J1-SDA
	for (i=4; i<6 ; i++)
	{
		Write_Data = 0xFFFFFFFF & (~(1 << i));

		XGpio_SetDataDirection(&I2C_Bus, 1, 0xFFFFFFCF);
		XGpio_DiscreteWrite(&I2C_Bus, 1 , Write_Data );

		Write_Data = Write_Data & 0x0000003F;

		if (verbose) xil_printf("\r\nWriting to J1 Connector 0x%02.2X", Write_Data);


	//read from TMDS-TX-SCL, TMDS-TX-SDA


		Read_Data = XGpio_DiscreteRead(&I2C_Bus, 1);
		Read_Data = Read_Data & 0x0000003F;
		if (verbose) xil_printf("\r\nReading from J2 Connector 0x%02.2X", Read_Data);

		Write_Data = Write_Data & (~(1 << (i-2)));



	if( !(Read_Data == Write_Data))
	{
		err++;
		if (verbose) xil_printf("\r\n Error, expected 0x%02.2X, got 0x%02.2X, pin number %d ", Write_Data , Read_Data, (5-i));
		Error_Code = i;
		if (verbose) xil_printf("\r\n Error Code = 0x%08.8X", Error_Code);
	}
	}

		if (!(err)) return XTEST_PASSED;
		else return Error_Code;
}

/***********************************************************************************************************************************
	Loopback test between JA and J3 Connectors
		//Pin 0  -----> JA-SCL (MSB)
		//Pin 1  -----> JA-SDA
		//Pin 4  -----> TMDS-RX-SCL
		//Pin 5  -----> TMDS-RX-SDA (LSB)

	Walk 0 on TMDS-RX-SCL, Read from JA-SCL
	Walk 0 on TMDS-RX-SDA, Read from JA-SDA

	In order to test HDMI connectors, plug a HDMI-A / HDMI-D cable into J3 and JA connectors

************************************************************************************************************************************/
Xuint32 I2C_Loopback_Test_2(XGpio I2C_Bus)
{
	Xuint32 Write_Data;
	Xuint32 Read_Data;

	Xuint32 i;
	Xuint32 err;
	Xuint32 Error_Code;

	err = 0;
	Error_Code = 0;

	Write_Data = 0xFFFFFFFF;


	// walk 0 on TMDS-RX-SCL, TMDS-RX-SDA
	for (i=0; i<2 ; i++)
	{
		Write_Data = 0xFFFFFFFF & (~(1 << i));

		XGpio_SetDataDirection(&I2C_Bus, 1, 0xFFFFFFFC);
		XGpio_DiscreteWrite(&I2C_Bus, 1 , Write_Data );

		Write_Data = Write_Data & 0x0000003F;

		if (verbose) xil_printf("\r\nWriting to J3 Connector 0x%02.2X", Write_Data);


	//read from JA-SCL, JA-SDA

	//	XGpio_SetDataDirection(&I2C_Bus, 1, 0xFFFFFFFF);
		Read_Data = XGpio_DiscreteRead(&I2C_Bus, 1);
		Read_Data = Read_Data & 0x0000003F;
		if (verbose) xil_printf("\r\nReading from JA Connector 0x%02.2X", Read_Data);

		Write_Data = Write_Data & (~(1 << (i+4)));

	if( !(Read_Data == Write_Data))
	{
		err++;
		if (verbose) xil_printf("\r\n Error, expected 0x%02.2X, got 0x%02.2X, pin number %d ", Write_Data , Read_Data, (5-i));
		Error_Code = i;
		if (verbose) xil_printf("\r\n Error Code = 0x%08.8X", Error_Code);
	}
	}

		if (!(err)) return XTEST_PASSED;
		else return Error_Code;
}


