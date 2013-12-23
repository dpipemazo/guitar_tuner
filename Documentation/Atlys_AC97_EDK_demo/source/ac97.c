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
/*	ac97.c	--	AC'97 Driver functions									*/
/*																		*/
/************************************************************************/
/*  Revision History:													*/
/* 																		*/
/*		11/4/2011(SamB): -Created ac97.c from BIST file ac97_if_00.c	*/
/*						 -Added Revision History						*/
/*						 -Removed BIST specific references to allow a	*/
/*						  more general usage.							*/
/*																		*/
/************************************************************************/


// Located in: microblaze_0/include/xparameters.h
#include "ac97.h"
#include "xparameters.h"
#include "xio.h"
#include "xbasic_types.h"
#include "xstatus.h"
#include "stdio.h"



	char C;
	Xuint32 Memory_Addr=0;
	Xuint32 sample=0;
	Xuint32 sample_num=0;

	Xuint32 TAG_AND_ID_DATA;
	Xuint32 btn_data;
	Xuint32 i;
	Xuint32 playback_rate = 0;
	Xuint32 recorded_short = 0;
	Xuint32 recorded_long = 0;
	Xuint32 processed_ok = 0;
	Xuint32 crt_menu = 0;
	Xuint32 SLOT_REQ = 0;
	Xuint32 variable_sample_rate = 24000;

	Xuint32 Count_Samples_Left;
	Xuint32 Count_Samples_Right;
	Xint32 crt_sample = 0;
	Xint32 prev_sample = 0;
	Xint32 processed_sample = 0;

int AC97_Link_Is_Ready (Xuint32 AC97_Baseaddr )
{
Xuint32 STATUS;

	XIo_Out32 ((AC97_Baseaddr + AC97_TAG_AND_ID_OFFSET), 0xF800);
	AC97_Wait_For_New_Frame (AC97_Baseaddr);
   STATUS = XIo_In32(AC97_Baseaddr + AC97_STATUS_OFFSET);
   if (STATUS & 0x80000000) return 1;
   else return 0;
}

void AC97_Wait_For_New_Frame (Xuint32 AC97_Baseaddr)
{
Xuint32 STATUS;
   STATUS = XIo_In32(AC97_Baseaddr + AC97_STATUS_OFFSET);
   STATUS = STATUS & 0xFFFF7FFF;
   XIo_Out32 ((AC97_Baseaddr + AC97_STATUS_OFFSET), STATUS);
   STATUS = XIo_In32(AC97_Baseaddr + AC97_STATUS_OFFSET);
   while (!(STATUS & 0x8000)){
      STATUS = XIo_In32(AC97_Baseaddr + AC97_STATUS_OFFSET);
      }
}

void AC97_Set_Tag_And_Id (Xuint32 AC97_Baseaddr, Xuint16 TAG_AND_ID_DATA )
{
//Xuint32 STATUS;

	XIo_Out32 ((AC97_Baseaddr + AC97_TAG_AND_ID_OFFSET), TAG_AND_ID_DATA);
}




Xuint32 AC97_ReadReg (Xuint32 AC97_Baseaddr, Xuint32 Addr){

int REG_DATA;
Xuint32 AC97_REG_DATA;
Xuint32 TAG_AND_ID_DATA;
Xuint32 STATUS;
Xuint32 Temp_Addr;
//Xuint32 i=0;

   //clear STATUS register and wait for one more frame
	AC97_Wait_For_New_Frame (AC97_Baseaddr);

   //set tag data: bit 4 - valid data in at least one slot, bit 3 - valid address
   TAG_AND_ID_DATA = 0xE000;
   AC97_Set_Tag_And_Id (AC97_Baseaddr, TAG_AND_ID_DATA );

   XIo_Out32 ((AC97_Baseaddr + AC97_CONFIG_DATA_OFFSET), 0x0);
   //set address register and RNW
   Temp_Addr = Addr | 0x80;
   XIo_Out32 ((AC97_Baseaddr + AC97_ADDR_OFFSET), Temp_Addr);

   //wait for two more new frames
   AC97_Wait_For_New_Frame (AC97_Baseaddr);
//   STATUS1 = XIo_In32 (AC97_Baseaddr + AC97_STATUS_OFFSET);
   AC97_Wait_For_New_Frame (AC97_Baseaddr);


   XIo_Out32 (AC97_Baseaddr + AC97_STATUS_OFFSET, 0x00);
   STATUS = XIo_In32 (AC97_Baseaddr + AC97_STATUS_OFFSET);
   while (!(STATUS &0xE0000000))
   {
   	STATUS = XIo_In32 (AC97_Baseaddr + AC97_STATUS_OFFSET);
   	//xil_printf("\r\nStatus = 0x%X", STATUS);
   }

   //if (verbose==2) xil_printf("\r\nStatus register value after register read = 0x%X, 0x%X", STATUS1, STATUS);
//   if (STATUS &0xA0000000)
//   {
    	AC97_REG_DATA = XIo_In32 (AC97_Baseaddr + AC97_CONFIG_DATA_OFFSET);
//	  	TAG_AND_ID_DATA = 0x9800;
// 		AC97_Set_Tag_And_Id (AC97_Baseaddr, TAG_AND_ID_DATA );
	  	REG_DATA = AC97_REG_DATA >> 16;
    	return REG_DATA;
//   }

//   else return 0xFFFF;

}


Xuint32 AC97_WriteReg (Xuint32 AC97_Baseaddr, Xuint32 Addr, Xuint16 DATA){


//Xuint32 AC97_REG_DATA;
Xuint32 TAG_AND_ID_DATA;
Xuint32 STATUS;
Xuint32 Temp_Addr;
//Xuint32 i=0;

   //clear STATUS register and wait for one more frame
	AC97_Wait_For_New_Frame (AC97_Baseaddr);

   //set tag data: bit 4 - valid data in at least one slot, bit 3 - valid address
   TAG_AND_ID_DATA = 0xE000;
   AC97_Set_Tag_And_Id (AC97_Baseaddr, TAG_AND_ID_DATA );

   XIo_Out32 ((AC97_Baseaddr + AC97_CONFIG_DATA_OFFSET), (0x00000000 | DATA));
   //set address register and RNW
   Temp_Addr = Addr & 0x0000007F;
   XIo_Out32 ((AC97_Baseaddr + AC97_ADDR_OFFSET), Temp_Addr);

   //wait for two more new frames
   AC97_Wait_For_New_Frame (AC97_Baseaddr);
//   AC97_Wait_For_New_Frame (AC97_Baseaddr);
//   AC97_Wait_For_New_Frame (AC97_Baseaddr);
//   AC97_Wait_For_New_Frame (AC97_Baseaddr);


   //clear the RNW bit
//   Temp_Addr = Addr | 0x80;
//   XIo_Out32 ((AC97_Baseaddr + AC97_ADDR_OFFSET), Temp_Addr);

   //STATUS = XIo_In32 (AC97_Baseaddr + AC97_STATUS_OFFSET);

   //if (verbose==2) xil_printf("\r\nStatus register value after register write = 0x%X", STATUS);

   XIo_Out32 (AC97_Baseaddr + AC97_STATUS_OFFSET, 0x00);
   STATUS = XIo_In32 (AC97_Baseaddr + AC97_STATUS_OFFSET);
   while (!(STATUS &0xE0000000))
   {
   	STATUS = XIo_In32 (AC97_Baseaddr + AC97_STATUS_OFFSET);
//   	xil_printf("\r\nStatus = 0x%X", STATUS);
   }

//     	AC97_REG_DATA = XIo_In32 (AC97_Baseaddr + AC97_CONFIG_DATA_OFFSET);
//	  	xil_printf("\r\nAC97_REG_DATA after write = 0x%X", AC97_REG_DATA);
//		TAG_AND_ID_DATA = 0x9800;
//   	AC97_Set_Tag_And_Id (AC97_Baseaddr, TAG_AND_ID_DATA );
	  	return DATA;
 }


int AC97_Select_Input (Xuint32 AC97_Baseaddr, char channel, char input)
{
//input can be  AC97_MIC_SELECT 0x00
//or  AC97_LINE_IN_SELECT	0x04

Xuint16 register_data, temp;
Xuint16 DATA;

	temp = 0x0000 | input;
	if (channel == LEFT_CHANNEL) register_data = (temp << 8);
	else if (channel == RIGHT_CHANNEL) register_data = temp;
	else if (channel == BOTH_CHANNELS) register_data = (temp << 8) | temp;
	else return 1;

    DATA = AC97_WriteReg (AC97_Baseaddr, AC97_INPUT_SELECT_OFFSET, register_data); //0x00 for microphone
    DATA = AC97_ReadReg (AC97_Baseaddr, AC97_INPUT_SELECT_OFFSET);
   return 0;
}

int AC97_Set_Volume (Xuint32 AC97_Baseaddr, char Volume_Reg, char channel, char volume)
{
//Volume_Reg values are:
//AC97_INPUT_SELECT_OFFSET		0x1A
//AC97_MASTER_VOLUME_OFFSET 		0x02
//AC97_HEADPHONE_VOLUME_OFFSET 	0x04
//AC97_MIC_VOLUME_OFFSET 			0x0e
//AC97_LINE_IN_VOLUME_OFFSET 		0x10
//AC97_PCM_OUT_VOLUME_OFFSET 		0x18
//AC97_RECORD_GAIN_OFFSET 		0x1C
Xuint16 register_data, temp;
Xuint16 DATA;

 	temp = 0x0000 | volume;
	if (channel == LEFT_CHANNEL) register_data = (temp << 8);
	else if (channel == RIGHT_CHANNEL) register_data = temp;
	else if (channel == BOTH_CHANNELS) register_data = (temp << 8) | temp;
	else return 1;

	DATA = AC97_WriteReg (AC97_Baseaddr, Volume_Reg, register_data);
    DATA = AC97_ReadReg (AC97_Baseaddr, Volume_Reg);
    return DATA;

}

int AC97_Mute (Xuint32 AC97_Baseaddr, char Volume_Reg)
{
//Volume_Reg values are:
//AC97_INPUT_SELECT_OFFSET		0x1A
//AC97_MASTER_VOLUME_OFFSET 		0x02
//AC97_HEADPHONE_VOLUME_OFFSET 	0x04
//AC97_MIC_VOLUME_OFFSET 			0x0e
//AC97_LINE_IN_VOLUME_OFFSET 		0x10
//AC97_PCM_OUT_VOLUME_OFFSET 		0x18
//AC97_RECORD_GAIN_OFFSET 		0x1C
Xuint16 register_data;
Xuint16 DATA;

	DATA = AC97_ReadReg (AC97_Baseaddr, Volume_Reg);
	register_data = DATA | (1 << MUTE);
	DATA = AC97_WriteReg (AC97_Baseaddr, Volume_Reg, register_data);
    DATA = AC97_ReadReg (AC97_Baseaddr, Volume_Reg);

	return DATA;
}

int AC97_Unmute (Xuint32 AC97_Baseaddr, char Volume_Reg)
{
//Volume_Reg values are:
//AC97_INPUT_SELECT_OFFSET		0x1A
//AC97_MASTER_VOLUME_OFFSET 		0x02
//AC97_HEADPHONE_VOLUME_OFFSET 	0x04
//AC97_MIC_VOLUME_OFFSET 			0x0e
//AC97_LINE_IN_VOLUME_OFFSET 		0x10
//AC97_PCM_OUT_VOLUME_OFFSET 		0x18
//AC97_RECORD_GAIN_OFFSET 		0x1C
Xuint16 register_data;
int DATA;

	DATA = AC97_ReadReg (AC97_Baseaddr, Volume_Reg);
	register_data = DATA & (~(1 <<MUTE));
	DATA = AC97_WriteReg (AC97_Baseaddr, Volume_Reg, register_data);
    DATA = AC97_ReadReg (AC97_Baseaddr, Volume_Reg);

	return DATA;
}

int AC97_IsMuted (Xuint32 AC97_Baseaddr, char Volume_Reg)
{
//returns 1 if the specified channel is muted, 0 if not
//Volume_Reg values are:
//AC97_INPUT_SELECT_OFFSET		0x1A
//AC97_MASTER_VOLUME_OFFSET 		0x02
//AC97_HEADPHONE_VOLUME_OFFSET 	0x04
//AC97_MIC_VOLUME_OFFSET 			0x0e
//AC97_LINE_IN_VOLUME_OFFSET 		0x10
//AC97_PCM_OUT_VOLUME_OFFSET 		0x18
//AC97_RECORD_GAIN_OFFSET 		0x1C
Xuint16 register_data;
int DATA;

	DATA = AC97_ReadReg (AC97_Baseaddr, Volume_Reg);
	register_data = DATA & (1 << MUTE );
	return (register_data >> MUTE);

}

void GenSquare (Xuint32 AC97_Baseaddr, u8 channel, int freq_HZ, int milisec)
{
	Xuint32 i, j;
	Xuint32 PCM_DATA;
	Xuint32 Status;
	Xuint32 TAG_AND_ID_DATA;
	Xuint32 count_skip_frame=0;
	int line_in_muted;
	int mic_muted;
	Xuint32 num_frames_send;
	Xuint32 Sample_Rate;

	i=0;

	Sample_Rate = Get_Sample_Rate (AC97_Baseaddr);

	//Here should be 1000 and 2, respectively. To review the calculations

	num_frames_send = (Sample_Rate /2000) * milisec;

	Xuint32 frames_to_skip = Sample_Rate / (4*freq_HZ);


	line_in_muted =  AC97_IsMuted (AC97_Baseaddr, AC97_LINE_IN_VOLUME_OFFSET);
	mic_muted = AC97_IsMuted (AC97_Baseaddr, AC97_MIC_VOLUME_OFFSET);

	//mute MIC and LINE-IN inputs if not muted and unmute PCM output first
    if (!(line_in_muted))
    		Status = AC97_Mute (AC97_Baseaddr, AC97_LINE_IN_VOLUME_OFFSET);

    if (!(mic_muted))
    	Status = AC97_Mute (AC97_Baseaddr, AC97_MIC_VOLUME_OFFSET);

    Status = AC97_Unmute (AC97_Baseaddr, AC97_MASTER_VOLUME_OFFSET);
   Status = AC97_Unmute (AC97_Baseaddr, AC97_HEADPHONE_VOLUME_OFFSET);
   Status = AC97_Unmute (AC97_Baseaddr, AC97_PCM_OUT_VOLUME_OFFSET);

//change TAG to send valid data in the PCM slots
   TAG_AND_ID_DATA = 0x9800;
   AC97_Set_Tag_And_Id (AC97_Baseaddr, TAG_AND_ID_DATA );

// set the first value for the PCM data;
   PCM_DATA = 0x0001FFFF;


// wait for a frame
   AC97_Wait_For_New_Frame (AC97_Baseaddr);

   j=0;
	//send the square-wave frames
	while (j<num_frames_send)
	{
	   j++;
	   //wait for the next frame;
	  AC97_Wait_For_New_Frame (AC97_Baseaddr);

	  //send out PCM_DATA to the AC'97 codec
	  switch (channel)
	  {
	  case LEFT_CHANNEL:{
	  		XIo_Out32 ((AC97_Baseaddr + AC97_PCM_OUT_L_OFFSET), PCM_DATA);
	   		XIo_Out32 ((AC97_Baseaddr + AC97_PCM_OUT_R_OFFSET), 0x00000000);
	  }
	  break;
	  case RIGHT_CHANNEL:
	  {
	  		XIo_Out32 ((AC97_Baseaddr + AC97_PCM_OUT_L_OFFSET), 0x00000000);
	   		XIo_Out32 ((AC97_Baseaddr + AC97_PCM_OUT_R_OFFSET), PCM_DATA);
	  }
	  break;
	  case BOTH_CHANNELS:
	  {
	  		XIo_Out32 ((AC97_Baseaddr + AC97_PCM_OUT_L_OFFSET), PCM_DATA);
	   		XIo_Out32 ((AC97_Baseaddr + AC97_PCM_OUT_R_OFFSET), PCM_DATA);
	  }
	  break;
	  }

	  //wait until the PCM data has to be changed
	  count_skip_frame++;
	  if (count_skip_frame >= frames_to_skip)
	  {
	   PCM_DATA = ~PCM_DATA;
	   count_skip_frame = 0;
	  }
	}

	//set 0 to both PCM channels in order to not let the amplifier close to saturation
	XIo_Out32 ((AC97_Baseaddr + AC97_PCM_OUT_L_OFFSET), 0x00);
    XIo_Out32 ((AC97_Baseaddr + AC97_PCM_OUT_R_OFFSET), 0x00);

	//unmute MIC and LINE-IN inputs if were muted previously
    if (!(line_in_muted))
   		Status = AC97_Unmute (AC97_Baseaddr, AC97_LINE_IN_VOLUME_OFFSET);

    if (!(mic_muted))
    	Status = AC97_Unmute (AC97_Baseaddr, AC97_MIC_VOLUME_OFFSET);

}



//**MODIFICAT DE MIHAI***********************************************************************************
//*******************************************************************************************************

int Get_Sample_Rate (Xuint32 AC97_Baseaddr)
{
	Xuint32 read_VRA;
	Xuint32 SAMPLE_RATE;

	read_VRA = AC97_ReadReg (AC97_Baseaddr, VRA_REG);
	//if (read_VRA == 0)
	//	SAMPLE_RATE = 48000;
	//else
		SAMPLE_RATE = AC97_ReadReg (AC97_Baseaddr, DAC_RATE_REG);

	return SAMPLE_RATE;
}

Xuint32 Read_PCM_Samples (Xuint32 AC97_Baseaddr, Xuint32 * MEM_ADDRESS, char channel)
{
//returns the number of samples read
Xuint32 * ADDRESS;
Xuint32 TAG_AND_ID_DATA;
//change TAG to send valid data in the PCM slots
   TAG_AND_ID_DATA = 0x9800;
   AC97_Set_Tag_And_Id (AC97_Baseaddr, TAG_AND_ID_DATA );
   // wait for a frame
   AC97_Wait_For_New_Frame (AC97_Baseaddr);

   ADDRESS = MEM_ADDRESS;

	if (channel == LEFT_CHANNEL)
	{
		* ADDRESS = (*(Xuint32 *) (AC97_Baseaddr + AC97_PCM_IN_L_OFFSET));
		return 1;
	}
	else if (channel == RIGHT_CHANNEL)
	{
		* ADDRESS = (*(Xuint32 *) (AC97_Baseaddr + AC97_PCM_IN_R_OFFSET));
		return 1;
	}
	else if (channel == BOTH_CHANNELS)
	{
		* ADDRESS = (*(Xuint32 *) (AC97_Baseaddr + AC97_PCM_IN_L_OFFSET));
		ADDRESS++;
		* ADDRESS = (*(Xuint32 *) (AC97_Baseaddr + AC97_PCM_IN_R_OFFSET));
		return 2;
	}
	else return 3;

 }

int CheckSlotRequestPCM (Xuint32 AC97_Baseaddr)
{
	Xuint32 VALID = 2;
	Xuint32 STATUS;
	STATUS = XIo_In32(AC97_Baseaddr + AC97_STATUS_OFFSET);
//	xil_printf("\r\nAC97 Status  = 0x%X", STATUS);
	STATUS = STATUS & STATUS_MASK_SLOT_REQ_PCM_BOTH;	// mask the 2 PCM L & R bits (bits 20 and 21)

	//SLOTREQ bits are active in low state (0) !
	if (!STATUS) VALID = 2;		//both bits are active (low)
   	else if (STATUS == STATUS_MASK_SLOT_REQ_PCM_LEFT) VALID = 3;	//PCM LEFT active only
   	 else if (STATUS == STATUS_MASK_SLOT_REQ_PCM_RIGHT) VALID = 4;	//PCM RIGHT active only
   	  else VALID = 1;			//both bits are inactive (high)
   	return VALID;
}

Xuint32 Write_PCM_Samples_LR (Xuint32 AC97_Baseaddr, Xuint32 * ADDRESS_LEFT, Xuint32 * ADDRESS_RIGHT, char channel)
{
Xuint32 TAG_AND_ID_DATA;
//change TAG to send valid data in the PCM slots
	if (channel == BOTH_CHANNELS)
		{
			TAG_AND_ID_DATA = 0x9FF8; //both LEFT and RIGHT PCM slots are valid
			AC97_Set_Tag_And_Id (AC97_Baseaddr, TAG_AND_ID_DATA );
		}
	else if (channel == LEFT_CHANNEL)
		{
			TAG_AND_ID_DATA = 0x97F8; //only LEFT PCM slot is valid
			AC97_Set_Tag_And_Id (AC97_Baseaddr, TAG_AND_ID_DATA );
		}
	else if (channel == RIGHT_CHANNEL)
		{
			TAG_AND_ID_DATA = 0x8FF8; //only RIGHT PCM slot is valid
			AC97_Set_Tag_And_Id (AC97_Baseaddr, TAG_AND_ID_DATA );
		}


	// wait for a frame
	XIo_Out32 (AC97_Baseaddr + AC97_STATUS_OFFSET, 0x00);
	AC97_Wait_For_New_Frame (AC97_Baseaddr);


	if (channel == LEFT_CHANNEL)
	{
 		* (Xuint32 *) (AC97_Baseaddr + AC97_PCM_OUT_L_OFFSET) = * (ADDRESS_LEFT);
	}
	else if (channel == RIGHT_CHANNEL)
	{
		* (Xuint32 *) (AC97_Baseaddr + AC97_PCM_OUT_R_OFFSET) = * (ADDRESS_RIGHT);
	}
	else if (channel == BOTH_CHANNELS)
	{
		* (Xuint32 *) (AC97_Baseaddr + AC97_PCM_OUT_L_OFFSET) = * (ADDRESS_LEFT);
		* (Xuint32 *) (AC97_Baseaddr + AC97_PCM_OUT_R_OFFSET) = * (ADDRESS_RIGHT);
	}

	TAG_AND_ID_DATA = 0x0000;
	AC97_Set_Tag_And_Id (AC97_Baseaddr, TAG_AND_ID_DATA );

	return 0;
 }

Xuint32 Write_PCM_Samples (Xuint32 AC97_Baseaddr, Xuint32 * MEM_ADDRESS, char channel)
{
//returns the number of samples written
Xuint32 * ADDRESS;
Xuint32 TAG_AND_ID_DATA;
//change TAG to send valid data in the PCM slots
   TAG_AND_ID_DATA = 0x9800;
   AC97_Set_Tag_And_Id (AC97_Baseaddr, TAG_AND_ID_DATA );
   // wait for a frame
   AC97_Wait_For_New_Frame (AC97_Baseaddr);

   ADDRESS = MEM_ADDRESS;

	if (channel == LEFT_CHANNEL)
	{
 		* (Xuint32 *) (AC97_Baseaddr + AC97_PCM_OUT_L_OFFSET) = * (ADDRESS);
		return 1;
	}
	else if (channel == RIGHT_CHANNEL)
	{
	   * (Xuint32 *) (AC97_Baseaddr + AC97_PCM_OUT_R_OFFSET) = * (ADDRESS);
		return 1;
	}
	else if (channel == BOTH_CHANNELS)
	{
		* (Xuint32 *) (AC97_Baseaddr + AC97_PCM_OUT_L_OFFSET) = * (ADDRESS);
		ADDRESS++;
	   * (Xuint32 *) (AC97_Baseaddr + AC97_PCM_OUT_R_OFFSET) = * (ADDRESS);
		return 2;
	}
	else return 3;

 }
