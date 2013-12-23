/************************************************************************/
/*																		*/
/*	ac97_demo.c	--	AC'97 Demo Main Program								*/
/*																		*/
/************************************************************************/
/*	Author: Sam Bobrowicz												*/
/*	Copyright 2011, Digilent Inc.										*/
/************************************************************************/
/*  Module Description: 												*/
/*																		*/
/*	This program demonstrates the audio processing capabilities of the  */
/*  Atlys Development Board. The onboard push buttons provide the 		*/
/*  following functionality to the user:								*/
/*																		*/
/*  BTNR – Record a short period of audio and store it in memory. SW0	*/
/*		   selects either LINE IN (up) or MIC (down) as the input 		*/
/*		   source. LD0 will be illuminated while recording.				*/
/*	BTNL – Play back the recorded audio data on both LINE OUT and		*/
/*		   HP OUT. LD1 will be illuminated while playing data back.		*/
/*	BTND – Output a brief tone on both LINE OUT and HP OUT				*/
/*																		*/
/************************************************************************/
/*  Revision History:													*/
/* 																		*/
/*		11/4/2011(SamB): Created										*/
/*																		*/
/************************************************************************/


/* ------------------------------------------------------------ */
/*				Include File Definitions						*/
/* ------------------------------------------------------------ */
#include <stdio.h>
#include "platform.h"  //Contains Cache initializing function
#include "xparameters.h"  //The hardware configuration describing constants
#include "xgpio.h"	//GPIO API functions
#include "xintc.h"	//Interrupt Controller API functions
#include "xil_io.h"	//Contains the Xil_Out32 and Xil_In32 functions
#include "mb_interface.h" //Contains the functions for registering the
						  //interrupt controller with the microblaze MP
#include "ac97_demo.h"
#include "ac97.h"

/* ------------------------------------------------------------ */
/*				XPAR Constants									*/
/* ------------------------------------------------------------ */
/* All constants used from xparameters.h are located here so 	*/
/* that they may be easily accessed.							*/
/**/

#define AC97_BASEADDR XPAR_DIGILENT_AC97_CNTLR_BASEADDR
#define BTNS_BASEADDR XPAR_PUSH_BUTTONS_5BITS_BASEADDR
#define SW_BASEADDR XPAR_DIP_SWITCHES_8BITS_BASEADDR
#define LED_BASEADDR XPAR_LEDS_8BITS_BASEADDR
#define BTNS_DEVICE_ID XPAR_PUSH_BUTTONS_5BITS_DEVICE_ID
#define INTC_DEVICE_ID XPAR_INTC_0_DEVICE_ID
#define BTNS_IRPT_ID XPAR_INTC_SINGLE_DEVICE_ID
#define DDR2_BASEADDR XPAR_MCB_DDR2_S0_AXI_BASEADDR

/*
 * The pAudioMem constant points to the physical address of the
 * start of the audio data in the DDR2 memory. It is offset from
 * the beginning of DDR to allow room for program memory
 */
#define pAudioData (DDR2_BASEADDR + 0x01000000)

/* ------------------------------------------------------------ */
/*				Global Variables								*/
/* ------------------------------------------------------------ */

volatile u32 lBtnStateOld;
volatile u8 fsRunAction; //flags are set by interrupts to trigger
						 //different actions

/* ------------------------------------------------------------ */
/*				Procedure Definitions							*/
/* ------------------------------------------------------------ */

int main()
{
    init_platform();

    static XGpio pshBtns;
    static XIntc intCtrl;

    Xuint32 Count_Samples;
    Xuint32 Sample_L;
    Xuint32 Sample_R;

    lBtnStateOld = 0x00000000;
    fsRunAction = 0;

	/*
	 *Initialize the driver structs for the Push button and interrupt cores.
	 *This allows the API functions to be used with these cores.
	 */
	XGpio_Initialize(&pshBtns, BTNS_DEVICE_ID);
	XIntc_Initialize(&intCtrl, INTC_DEVICE_ID);

	/*
	 * Connect the function PushBtnHandler to the interrupt controller so that
	 * it is called whenever the Push button GPIO core signals an interrupt.
	 */
	XIntc_Connect(&intCtrl, BTNS_IRPT_ID, PushBtnHandler, &pshBtns);

	/*
	 * Enable interrupts at the interrupt controller
	 */
	XIntc_Enable(&intCtrl, BTNS_IRPT_ID);

	/*
	 * Register the interrupt controller with the microblaze
	 * processor and then start the Interrupt controller so that it begins
	 * listening to the interrupt core for triggers.
	 */
	microblaze_register_handler(XIntc_DeviceInterruptHandler, INTC_DEVICE_ID);
	microblaze_enable_interrupts();
	XIntc_Start(&intCtrl, XIN_REAL_MODE);

	/*
	 * Enable the push button GPIO core to begin sending interrupts to the
	 * interrupt controller in response to changes in the button states
	 */
	XGpio_InterruptEnable(&pshBtns, lBtnChannel);
	XGpio_InterruptGlobalEnable(&pshBtns);

	/*
	 * Wait for AC97 to become ready
	 */
    while (!(AC97_Link_Is_Ready (AC97_BASEADDR)));

    /*
     * Set TAG to configure codec
     */
    AC97_Set_Tag_And_Id (AC97_BASEADDR, 0xF800);

    /*
     * Enable audio output and set volume
     */
    AC97_Unmute (AC97_BASEADDR, AC97_MASTER_VOLUME_OFFSET);
    AC97_Unmute (AC97_BASEADDR, AC97_HEADPHONE_VOLUME_OFFSET);
    AC97_Unmute (AC97_BASEADDR, AC97_PCM_OUT_VOLUME_OFFSET);

    AC97_Set_Volume (AC97_BASEADDR, AC97_MASTER_VOLUME_OFFSET,
       						     BOTH_CHANNELS, VOLUME_MAX);
    AC97_Set_Volume (AC97_BASEADDR, AC97_HEADPHONE_VOLUME_OFFSET,
       						     BOTH_CHANNELS, VOLUME_MIN);
    AC97_Set_Volume (AC97_BASEADDR, AC97_PCM_OUT_VOLUME_OFFSET,
       						     BOTH_CHANNELS, VOLUME_MAX);


    while (1)
    {
    	/**************************
    	 * Play recorded sample
    	 **************************/
    	if (fsRunAction & bitPlay)
    	{
    		/*
			 * Set AC'97 codec TAG to send and receive data in the PCM slots
			 */
			AC97_Set_Tag_And_Id (AC97_BASEADDR, 0x9800);

			Count_Samples =  0;

			Xil_Out32(LED_BASEADDR, bitPlayLED); //turn on LED

			while ((Count_Samples/8) < lNumSamples)
			{
				/*
				 * Block execution until next frame is ready
				 */
				AC97_Wait_For_New_Frame (AC97_BASEADDR);

				/*
				 * Read audio data from memory
				 */
				Sample_L = XIo_In32 (pAudioData + Count_Samples);
				Count_Samples = Count_Samples +4;
				Sample_R = XIo_In32 (pAudioData + Count_Samples);
				Count_Samples = Count_Samples +4;

				/*
				 * Send audio data to codec
				 */
				XIo_Out32 ((AC97_BASEADDR + AC97_PCM_OUT_L_OFFSET), Sample_L);
				XIo_Out32 ((AC97_BASEADDR + AC97_PCM_OUT_R_OFFSET), Sample_R);
			}

			Xil_Out32(LED_BASEADDR, 0); //Turn off LED
			fsRunAction = 0; //Forget any button presses that occurred
    	}
    	/**************************
    	 * Output a square wave
    	 **************************/
    	if (fsRunAction & bitGenWave)
    	{
    		//generate square on left, right and then both channels
    		GenSquare(AC97_BASEADDR, LEFT_CHANNEL, 1000, 500);
    		GenSquare(AC97_BASEADDR, RIGHT_CHANNEL, 1000, 500);
    		GenSquare(AC97_BASEADDR, BOTH_CHANNELS, 1000, 500);
    		fsRunAction = 0;
    	}
    	/**************************
    	 * Record audio from input
    	 **************************/
    	if (fsRunAction & bitRec)
    	{
    		AC97_Set_Tag_And_Id (AC97_BASEADDR, 0xF800); //Set to configure

    		/*
    		 * Select input source, enable it, and then set the volume
    		 */
    		if (Xil_In32(SW_BASEADDR) & bitSw0)
			{
			   AC97_Select_Input (AC97_BASEADDR, BOTH_CHANNELS,
									   AC97_LINE_IN_SELECT);
			   AC97_Unmute (AC97_BASEADDR, AC97_LINE_IN_VOLUME_OFFSET);
			   AC97_Set_Volume (AC97_BASEADDR, AC97_LINE_IN_VOLUME_OFFSET,
									 BOTH_CHANNELS, VOLUME_MAX);
			}
			else
			{
				AC97_Select_Input (AC97_BASEADDR, BOTH_CHANNELS,
									   AC97_MIC_SELECT);
				AC97_Unmute (AC97_BASEADDR, AC97_MIC_VOLUME_OFFSET);
				AC97_Set_Volume (AC97_BASEADDR, AC97_MIC_VOLUME_OFFSET,
									BOTH_CHANNELS, VOLUME_MID);
			}
			//set record gain
			AC97_Set_Volume (AC97_BASEADDR, AC97_RECORD_GAIN_OFFSET,
									 BOTH_CHANNELS, 0x00);

		   AC97_Set_Tag_And_Id (AC97_BASEADDR, 0x9800); //Set to Send/Receive data

		   Count_Samples =  0;

		   Xil_Out32(LED_BASEADDR, bitRecLED);  //Turn on LED

		   while ((Count_Samples/8) < lNumSamples)
		   {
				 AC97_Wait_For_New_Frame (AC97_BASEADDR);

				/*
				 * Read audio data from codec
				 */
				Sample_L = XIo_In32(AC97_BASEADDR + AC97_PCM_IN_L_OFFSET);
				Sample_R = XIo_In32(AC97_BASEADDR + AC97_PCM_IN_R_OFFSET);

				/*
				 * Write audio data to memory
				 */
				XIo_Out32 (pAudioData + Count_Samples, Sample_L);
				Count_Samples = Count_Samples +4;
				XIo_Out32 (pAudioData + Count_Samples, Sample_R);
				Count_Samples = Count_Samples +4;
		   }

			//Set Tag and ID to configure the codec
			AC97_Set_Tag_And_Id (AC97_BASEADDR, 0xF800);

		   /*
		    * Disable the input source
		    */
		   if (Xil_In32(SW_BASEADDR) & bitSw0)
		   {
			  AC97_Mute (AC97_BASEADDR, AC97_LINE_IN_VOLUME_OFFSET);
		   }
		   else
		   {
			  AC97_Mute (AC97_BASEADDR, AC97_MIC_VOLUME_OFFSET);
		   }

		   Xil_Out32(LED_BASEADDR, 0); //Turn off LED
    	   fsRunAction = 0;
    	}

    }

    cleanup_platform();

    return 0;
}

/***	PushBtnHandler
**
**	Parameters:
**		CallBackRef - Pointer to the push button struct (pshBtns) initialized
**		in main.
**
**	Return Value:
**		None
**
**	Errors:
**		None
**
**	Description:
**		Respond to various button pushes by triggering actions to occur outside
**		the ISR. Actions are triggered by setting flags within the fsRunAction
**		flag set variable.
*/
void PushBtnHandler(void *CallBackRef)
{
	XGpio *pPushBtn = (XGpio *)CallBackRef;
	u32 lBtnStateNew = XGpio_DiscreteRead(pPushBtn, lBtnChannel);
	u32 lBtnChanges = lBtnStateNew ^ lBtnStateOld;

    if (fsRunAction == 0)
    {
		if ((lBtnChanges & bitBtnD) && (lBtnStateNew & bitBtnD))
		{
			fsRunAction = fsRunAction | bitGenWave;
		}
		if ((lBtnChanges & bitBtnL) && (lBtnStateNew & bitBtnL))
		{
			fsRunAction = fsRunAction | bitPlay;
		}
		if ((lBtnChanges & bitBtnR) && (lBtnStateNew & bitBtnR))
		{
			fsRunAction = fsRunAction | bitRec;
		}
    }


	lBtnStateOld = lBtnStateNew;

	XGpio_InterruptClear(pPushBtn, lBtnChannel);
}
