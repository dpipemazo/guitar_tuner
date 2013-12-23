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
 * Xilinx EDK 11.2 EDK_LS2.6
 *
 * This file is a sample test application
 *
 * This application is intended to test and/or illustrate some
 * functionality of your system.  The contents of this file may
 * vary depending on the IP in your system and may use existing
 * IP driver functions.  These drivers will be generated in your
 * XPS project when you run the "Generate Libraries" menu item
 * in XPS.
*/

/************************************************************************/
/*																		*/
/*	ac97.h	--	AC'97 Driver functions									*/
/*																		*/
/************************************************************************/
/*  Revision History:													*/
/* 																		*/
/*		11/4/2011(SamB): -Created ac97.h from BIST file ac97_if_00.h	*/
/*						 -Added Revision History						*/
/*						 -Removed BIST specific references to allow a	*/
/*						  more general usage.							*/
/*																		*/
/************************************************************************/


// Located in: microblaze_0/include/xparameters.h

#ifndef AC97_H
#define AC97_H

#include "xparameters.h"
#include "xio.h"
#include "xbasic_types.h"
#include "xstatus.h"

/************************** Constant Definitions ****************************/
/**
 * The following constants map to the XPAR parameters created in the
 * xparameters.h file. They are defined here such that a user can easily
 * change all the needed parameters in one place.
 */


#define AC97_ADDR_OFFSET         		0x00
#define AC97_CONFIG_DATA_OFFSET  		0x04
#define AC97_PCM_OUT_L_OFFSET    		0x08
#define AC97_PCM_OUT_R_OFFSET    		0x0C
#define AC97_PCM_IN_L_OFFSET     		0x10
#define AC97_PCM_IN_R_OFFSET     		0x14
#define AC97_TAG_AND_ID_OFFSET   		0x18
#define AC97_CONTROL_OFFSET      		0x18
#define AC97_STATUS_OFFSET       		0x1C

#define AC97_MIC_SELECT			 		0x00
#define AC97_LINE_IN_SELECT		 		0x04

#define AC97_INPUT_SELECT_OFFSET		0x1A
#define AC97_MASTER_VOLUME_OFFSET 		0x02
#define AC97_HEADPHONE_VOLUME_OFFSET 	0x04
#define AC97_MONO_VOLUME_OFFSET 		0x06
#define AC97_MIC_VOLUME_OFFSET 			0x0E
#define AC97_LINE_IN_VOLUME_OFFSET 		0x10
#define AC97_PCM_OUT_VOLUME_OFFSET 		0x18
#define AC97_RECORD_GAIN_OFFSET 		0x1C

#define MUTE 			15
#define boost20dB 		6

#define VOLUME_MAX 		0x0
#define VOLUME_MID		0x08
#define VOLUME_MIN 		0x1f

#define GAIN_MAX		0x0f
#define GAIN_MID        0x08
#define GAIN_MIN		0x00

#define LEFT_CHANNEL	0x01
#define RIGHT_CHANNEL	0x02
#define BOTH_CHANNELS	0x00

//**MODIFICAT DE MIHAI***********************

#define MIN_FREQ_HZ 	4000  //minimum sample rate frequency in Hz
#define MAX_FREQ_HZ		48000 //maximum sample rate frequency in Hz
#define DAC_RATE_REG	0x2C
#define ADC_RATE_REG	0x32
#define VRA_REG			0x2A


#define STATUS_MASK_FRAME_VALID 			0x80000000
#define STATUS_MASK_SLOT_VALID_PCM_LEFT		0x10000000
#define STATUS_MASK_SLOT_VALID_PCM_RIGHT	0x08000000
#define STATUS_MASK_SLOT_VALID_PCM_BOTH		0x18000000
#define STATUS_MASK_SLOT_REQ_PCM_LEFT		0x00000800
#define STATUS_MASK_SLOT_REQ_PCM_RIGHT		0x00000400
#define STATUS_MASK_SLOT_REQ_PCM_BOTH		0x00000C00

#define TWOS_COMPLEMENT_SIGN_MASK 		0x80000
#define TWOS_COMPLEMENT_NEG_VALUE_MASK	0xFFF00000

// for function Read_PCM_Samples_SlotValid, the return value specifies nr. of samples read
#define LEFT_SAMPLE_COUNT_MASK   		0x01
#define RIGHT_SAMPLE_COUNT_MASK   		0x02
#define ANY_SAMPLE_COUNT_MASK 			(LEFT_SAMPLE_COUNT_MASK | RIGHT_SAMPLE_COUNT_MASK)


int AC97_Link_Is_Ready (Xuint32 AC97_Baseaddr );
void AC97_Wait_For_New_Frame (Xuint32 AC97_Baseaddr);
void AC97_Set_Tag_And_Id (Xuint32 AC97_Baseaddr, Xuint16 TAG_AND_ID_DATA );
Xuint32 AC97_ReadReg (Xuint32 AC97_Baseaddr, Xuint32 Addr);
Xuint32 AC97_WriteReg (Xuint32 AC97_Baseaddr, Xuint32 Addr, Xuint16 DATA);
int AC97_Select_Input (Xuint32 AC97_Baseaddr, char channel, char input);
int AC97_Set_Volume (Xuint32 AC97_Baseaddr, char Volume_Reg, char channel, char volume);
int AC97_Mute (Xuint32 AC97_Baseaddr, char Volume_Reg);
int AC97_Unmute (Xuint32 AC97_Baseaddr, char Volume_Reg);
int AC97_IsMuted (Xuint32 AC97_Baseaddr, char Volume_Reg);
void GenSquare (Xuint32 AC97_Baseaddr, u8 channel, int freq_HZ, int milisec);
Xuint32 Read_PCM_Samples (Xuint32 AC97_Baseaddr, Xuint32 * MEM_ADDRESS, char channel);
int CheckSlotRequestPCM (Xuint32 AC97_Baseaddr);
Xuint32 Write_PCM_Samples_LR (Xuint32 AC97_Baseaddr, Xuint32 * ADDRESS_LEFT, Xuint32 * ADDRESS_RIGHT, char channel);
Xuint32 Write_PCM_Samples (Xuint32 AC97_Baseaddr, Xuint32 * MEM_ADDRESS, char channel);
int Get_Sample_Rate (Xuint32 AC97_Baseaddr);

#endif
