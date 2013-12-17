
/*******************************************************************
*
* CAUTION: This file is automatically generated by libgen.
* Version: Xilinx EDK 12.2 EDK_MS2.63c
* DO NOT EDIT.
*
* Copyright (c) 1995-2010 Xilinx, Inc.  All rights reserved.

* 
* Description: Driver parameters
*
*******************************************************************/

#define STDIN_BASEADDRESS 0x83E00000
#define STDOUT_BASEADDRESS 0x83E00000

/******************************************************************/

/* Definitions for driver GPIO */
#define XPAR_XGPIO_NUM_INSTANCES 5

/* Definitions for peripheral DIP_SWITCHES_8BITS */
#define XPAR_DIP_SWITCHES_8BITS_BASEADDR 0x81480000
#define XPAR_DIP_SWITCHES_8BITS_HIGHADDR 0x8148FFFF
#define XPAR_DIP_SWITCHES_8BITS_DEVICE_ID 0
#define XPAR_DIP_SWITCHES_8BITS_INTERRUPT_PRESENT 0
#define XPAR_DIP_SWITCHES_8BITS_IS_DUAL 0


/* Definitions for peripheral I2C_BUS */
#define XPAR_I2C_BUS_BASEADDR 0x81460000
#define XPAR_I2C_BUS_HIGHADDR 0x8146FFFF
#define XPAR_I2C_BUS_DEVICE_ID 1
#define XPAR_I2C_BUS_INTERRUPT_PRESENT 0
#define XPAR_I2C_BUS_IS_DUAL 0


/* Definitions for peripheral LEDS_8BITS */
#define XPAR_LEDS_8BITS_BASEADDR 0x81440000
#define XPAR_LEDS_8BITS_HIGHADDR 0x8144FFFF
#define XPAR_LEDS_8BITS_DEVICE_ID 2
#define XPAR_LEDS_8BITS_INTERRUPT_PRESENT 0
#define XPAR_LEDS_8BITS_IS_DUAL 0


/* Definitions for peripheral PUSH_BUTTONS_5BITS */
#define XPAR_PUSH_BUTTONS_5BITS_BASEADDR 0x81420000
#define XPAR_PUSH_BUTTONS_5BITS_HIGHADDR 0x8142FFFF
#define XPAR_PUSH_BUTTONS_5BITS_DEVICE_ID 3
#define XPAR_PUSH_BUTTONS_5BITS_INTERRUPT_PRESENT 0
#define XPAR_PUSH_BUTTONS_5BITS_IS_DUAL 0


/* Definitions for peripheral VHDCI_CONN */
#define XPAR_VHDCI_CONN_BASEADDR 0x81400000
#define XPAR_VHDCI_CONN_HIGHADDR 0x8140FFFF
#define XPAR_VHDCI_CONN_DEVICE_ID 4
#define XPAR_VHDCI_CONN_INTERRUPT_PRESENT 0
#define XPAR_VHDCI_CONN_IS_DUAL 1


/******************************************************************/

/* Definitions for driver MPMC */
#define XPAR_XMPMC_NUM_INSTANCES 1

/* Definitions for peripheral MCB_DDR2 */
#define XPAR_MCB_DDR2_DEVICE_ID 0
#define XPAR_MCB_DDR2_MPMC_CTRL_BASEADDR 0xFFFFFFFF
#define XPAR_MCB_DDR2_INCLUDE_ECC_SUPPORT 0
#define XPAR_MCB_DDR2_USE_STATIC_PHY 0
#define XPAR_MCB_DDR2_PM_ENABLE 0
#define XPAR_MCB_DDR2_NUM_PORTS 2
#define XPAR_MCB_DDR2_MEM_DATA_WIDTH 16
#define XPAR_MCB_DDR2_MEM_PART_NUM_BANK_BITS 3
#define XPAR_MCB_DDR2_MEM_PART_NUM_ROW_BITS 13
#define XPAR_MCB_DDR2_MEM_PART_NUM_COL_BITS 10
#define XPAR_MCB_DDR2_MEM_TYPE DDR2
#define XPAR_MCB_DDR2_ECC_SEC_THRESHOLD 1
#define XPAR_MCB_DDR2_ECC_DEC_THRESHOLD 1
#define XPAR_MCB_DDR2_ECC_PEC_THRESHOLD 1
#define XPAR_MCB_DDR2_MEM_DQS_WIDTH 2
#define XPAR_MCB_DDR2_MPMC_CLK0_PERIOD_PS 15000


/******************************************************************/


/* Definitions for peripheral MCB_DDR2 */
#define XPAR_MCB_DDR2_MPMC_BASEADDR 0x48000000
#define XPAR_MCB_DDR2_MPMC_HIGHADDR 0x4FFFFFFF
#define XPAR_MCB_DDR2_SDMA_CTRL_BASEADDR 0x84600000
#define XPAR_MCB_DDR2_SDMA_CTRL_HIGHADDR 0x8460FFFF
#define XPAR_MCB_DDR2_BASEADDR_CTRL0 0x000
#define XPAR_MCB_DDR2_HIGHADDR_CTRL0 0x00d
#define XPAR_MCB_DDR2_BASEADDR_CTRL2 0x018
#define XPAR_MCB_DDR2_HIGHADDR_CTRL2 0x025
#define XPAR_MCB_DDR2_BASEADDR_CTRL3 0x026
#define XPAR_MCB_DDR2_HIGHADDR_CTRL3 0x02f
#define XPAR_MCB_DDR2_BASEADDR_CTRL4 0x030
#define XPAR_MCB_DDR2_HIGHADDR_CTRL4 0x03d
#define XPAR_MCB_DDR2_BASEADDR_CTRL5 0x03e
#define XPAR_MCB_DDR2_HIGHADDR_CTRL5 0x047
#define XPAR_MCB_DDR2_BASEADDR_CTRL6 0x048
#define XPAR_MCB_DDR2_HIGHADDR_CTRL6 0x05b
#define XPAR_MCB_DDR2_BASEADDR_CTRL7 0x05c
#define XPAR_MCB_DDR2_HIGHADDR_CTRL7 0x06a
#define XPAR_MCB_DDR2_BASEADDR_CTRL8 0x06b
#define XPAR_MCB_DDR2_HIGHADDR_CTRL8 0x086
#define XPAR_MCB_DDR2_BASEADDR_CTRL9 0x087
#define XPAR_MCB_DDR2_HIGHADDR_CTRL9 0x09d
#define XPAR_MCB_DDR2_BASEADDR_CTRL10 0x09e
#define XPAR_MCB_DDR2_HIGHADDR_CTRL10 0x0a5
#define XPAR_MCB_DDR2_BASEADDR_CTRL11 0x0a6
#define XPAR_MCB_DDR2_HIGHADDR_CTRL11 0x0ad
#define XPAR_MCB_DDR2_BASEADDR_CTRL12 0x0ae
#define XPAR_MCB_DDR2_HIGHADDR_CTRL12 0x0b5
#define XPAR_MCB_DDR2_BASEADDR_CTRL13 0x0b6
#define XPAR_MCB_DDR2_HIGHADDR_CTRL13 0x0bd
#define XPAR_MCB_DDR2_BASEADDR_CTRL14 0x0be
#define XPAR_MCB_DDR2_HIGHADDR_CTRL14 0x0d0
#define XPAR_MCB_DDR2_BASEADDR_CTRL15 0x0d1
#define XPAR_MCB_DDR2_HIGHADDR_CTRL15 0x0d8
#define XPAR_MCB_DDR2_BASEADDR_CTRL16 0x0d9
#define XPAR_MCB_DDR2_HIGHADDR_CTRL16 0x0da


/******************************************************************/

/* Canonical definitions for peripheral MCB_DDR2 */
#define XPAR_MPMC_0_DEVICE_ID XPAR_MCB_DDR2_DEVICE_ID
#define XPAR_MPMC_0_MPMC_BASEADDR 0x48000000
#define XPAR_MPMC_0_MPMC_HIGHADDR 0x4FFFFFFF
#define XPAR_MPMC_0_MPMC_CTRL_BASEADDR 0xFFFFFFFF
#define XPAR_MPMC_0_INCLUDE_ECC_SUPPORT 0
#define XPAR_MPMC_0_USE_STATIC_PHY 0
#define XPAR_MPMC_0_PM_ENABLE 0
#define XPAR_MPMC_0_NUM_PORTS 2
#define XPAR_MPMC_0_MEM_DATA_WIDTH 16
#define XPAR_MPMC_0_MEM_PART_NUM_BANK_BITS 3
#define XPAR_MPMC_0_MEM_PART_NUM_ROW_BITS 13
#define XPAR_MPMC_0_MEM_PART_NUM_COL_BITS 10
#define XPAR_MPMC_0_MEM_TYPE DDR2
#define XPAR_MPMC_0_ECC_SEC_THRESHOLD 1
#define XPAR_MPMC_0_ECC_DEC_THRESHOLD 1
#define XPAR_MPMC_0_ECC_PEC_THRESHOLD 1
#define XPAR_MPMC_0_MEM_DQS_WIDTH 2
#define XPAR_MPMC_0_MPMC_CLK0_PERIOD_PS 15000


/******************************************************************/

/* Definitions for driver PS2 */
#define XPAR_XPS2_NUM_INSTANCES 2

/* Definitions for peripheral PS2_KEYBOARD_MOUSE Device 0 */
#define XPAR_PS2_KEYBOARD_MOUSE_0_DEVICE_ID 0
#define XPAR_PS2_KEYBOARD_MOUSE_0_BASEADDR 0x86a00000
#define XPAR_PS2_KEYBOARD_MOUSE_0_HIGHADDR 0x86A00FFF

/* Canonical definitions for peripheral PS2_KEYBOARD_MOUSE Device 0 */
#define XPAR_PS2_0_DEVICE_ID 0
#define XPAR_PS2_0_BASEADDR 0x86a00000
#define XPAR_PS2_0_HIGHADDR 0x86A00FFF


/* Definitions for peripheral PS2_KEYBOARD_MOUSE Device 1 */
#define XPAR_PS2_KEYBOARD_MOUSE_1_DEVICE_ID 1
#define XPAR_PS2_KEYBOARD_MOUSE_1_BASEADDR 0x86A01000
#define XPAR_PS2_KEYBOARD_MOUSE_1_HIGHADDR 0x86A01FFF

/* Canonical definitions for peripheral PS2_KEYBOARD_MOUSE Device 1 */
#define XPAR_PS2_1_DEVICE_ID 1
#define XPAR_PS2_1_BASEADDR 0x86A01000
#define XPAR_PS2_1_HIGHADDR 0x86A01FFF



/******************************************************************/

/* Definitions for driver LLTEMAC */
#define XPAR_XLLTEMAC_NUM_INSTANCES 1

/* Definitions for peripheral SOFT_TEMAC Channel 0 */
#define XPAR_SOFT_TEMAC_CHAN_0_DEVICE_ID 0
#define XPAR_SOFT_TEMAC_CHAN_0_BASEADDR 0x83e80000
#define XPAR_SOFT_TEMAC_CHAN_0_HIGHADDR 0x83efffff
#define XPAR_SOFT_TEMAC_CHAN_0_TXCSUM 0
#define XPAR_SOFT_TEMAC_CHAN_0_RXCSUM 0
#define XPAR_SOFT_TEMAC_CHAN_0_PHY_TYPE 1
#define XPAR_SOFT_TEMAC_CHAN_0_TXVLAN_TRAN 0
#define XPAR_SOFT_TEMAC_CHAN_0_RXVLAN_TRAN 0
#define XPAR_SOFT_TEMAC_CHAN_0_TXVLAN_TAG 0
#define XPAR_SOFT_TEMAC_CHAN_0_RXVLAN_TAG 0
#define XPAR_SOFT_TEMAC_CHAN_0_TXVLAN_STRP 0
#define XPAR_SOFT_TEMAC_CHAN_0_RXVLAN_STRP 0
#define XPAR_SOFT_TEMAC_CHAN_0_MCAST_EXTEND 0

/* Canonical definitions for peripheral SOFT_TEMAC Channel 0 */
#define XPAR_LLTEMAC_0_DEVICE_ID 0
#define XPAR_LLTEMAC_0_BASEADDR 0x83e80000
#define XPAR_LLTEMAC_0_HIGHADDR 0x83efffff
#define XPAR_LLTEMAC_0_TXCSUM 0
#define XPAR_LLTEMAC_0_RXCSUM 0
#define XPAR_LLTEMAC_0_PHY_TYPE 1
#define XPAR_LLTEMAC_0_TXVLAN_TRAN 0
#define XPAR_LLTEMAC_0_RXVLAN_TRAN 0
#define XPAR_LLTEMAC_0_TXVLAN_TAG 0
#define XPAR_LLTEMAC_0_RXVLAN_TAG 0
#define XPAR_LLTEMAC_0_TXVLAN_STRP 0
#define XPAR_LLTEMAC_0_RXVLAN_STRP 0
#define XPAR_LLTEMAC_0_MCAST_EXTEND 0
#define XPAR_LLTEMAC_0_INTR 4


/* LocalLink TYPE Enumerations */
#define XPAR_LL_FIFO    1
#define XPAR_LL_DMA     2


/* Canonical LocalLink parameters for SOFT_TEMAC */
#define XPAR_LLTEMAC_0_LLINK_CONNECTED_TYPE XPAR_LL_DMA
#define XPAR_LLTEMAC_0_LLINK_CONNECTED_BASEADDR 0x84600080
#define XPAR_LLTEMAC_0_LLINK_CONNECTED_FIFO_INTR 0xFF
#define XPAR_LLTEMAC_0_LLINK_CONNECTED_DMARX_INTR 6
#define XPAR_LLTEMAC_0_LLINK_CONNECTED_DMATX_INTR 5


/******************************************************************/


/* Definitions for peripheral AC97_IF_0 */
#define XPAR_AC97_IF_0_BASEADDR 0xCEE00000
#define XPAR_AC97_IF_0_HIGHADDR 0xCEE0FFFF


/* Definitions for peripheral PHY_RESET_COMPONENT_0 */
#define XPAR_PHY_RESET_COMPONENT_0_BASEADDR 0xC4000000
#define XPAR_PHY_RESET_COMPONENT_0_HIGHADDR 0xC400FFFF


/* Definitions for peripheral QUAD_SPI_IF_0 */
#define XPAR_QUAD_SPI_IF_0_BASEADDR 0xCF200000
#define XPAR_QUAD_SPI_IF_0_HIGHADDR 0xCF20FFFF


/******************************************************************/

/* Definitions for driver D_USB_EPP_DSTM */
#define XPAR_D_USB_EPP_DSTM_NUM_INSTANCES 1

/* Definitions for peripheral D_USB_EPP_DSTM_0 */
#define XPAR_D_USB_EPP_DSTM_0_DEVICE_ID 0
#define XPAR_D_USB_EPP_DSTM_0_BASEADDR 0xC7E00000
#define XPAR_D_USB_EPP_DSTM_0_HIGHADDR 0xC7E0FFFF


/******************************************************************/


/* Definitions for peripheral DLMB_CNTLR */
#define XPAR_DLMB_CNTLR_BASEADDR 0x00000000
#define XPAR_DLMB_CNTLR_HIGHADDR 0x0000FFFF


/* Definitions for peripheral ILMB_CNTLR */
#define XPAR_ILMB_CNTLR_BASEADDR 0x00000000
#define XPAR_ILMB_CNTLR_HIGHADDR 0x0000FFFF


/******************************************************************/

/* Definitions for driver UARTLITE */
#define XPAR_XUARTLITE_NUM_INSTANCES 1

/* Definitions for peripheral MDM_0 */
#define XPAR_MDM_0_BASEADDR 0x84400000
#define XPAR_MDM_0_HIGHADDR 0x8440FFFF
#define XPAR_MDM_0_DEVICE_ID 0
#define XPAR_MDM_0_BAUDRATE 0
#define XPAR_MDM_0_USE_PARITY 0
#define XPAR_MDM_0_ODD_PARITY 0
#define XPAR_MDM_0_DATA_BITS 0


/******************************************************************/


/* Canonical definitions for peripheral MDM_0 */
#define XPAR_UARTLITE_0_DEVICE_ID XPAR_MDM_0_DEVICE_ID
#define XPAR_UARTLITE_0_BASEADDR 0x84400000
#define XPAR_UARTLITE_0_HIGHADDR 0x8440FFFF
#define XPAR_UARTLITE_0_BAUDRATE 0
#define XPAR_UARTLITE_0_USE_PARITY 0
#define XPAR_UARTLITE_0_ODD_PARITY 0
#define XPAR_UARTLITE_0_DATA_BITS 0
#define XPAR_UARTLITE_0_SIO_CHAN -1


/******************************************************************/

#define XPAR_INTC_MAX_NUM_INTR_INPUTS 7
#define XPAR_XINTC_HAS_IPR 1
#define XPAR_XINTC_HAS_SIE 1
#define XPAR_XINTC_HAS_CIE 1
#define XPAR_XINTC_HAS_IVR 1
#define XPAR_XINTC_USE_DCR 0
/* Definitions for driver INTC */
#define XPAR_XINTC_NUM_INSTANCES 1

/* Definitions for peripheral XPS_INTC_0 */
#define XPAR_XPS_INTC_0_DEVICE_ID 0
#define XPAR_XPS_INTC_0_BASEADDR 0x81800000
#define XPAR_XPS_INTC_0_HIGHADDR 0x8180FFFF
#define XPAR_XPS_INTC_0_KIND_OF_INTR 0xFFFFFF80


/******************************************************************/

#define XPAR_INTC_SINGLE_BASEADDR 0x81800000
#define XPAR_INTC_SINGLE_HIGHADDR 0x8180FFFF
#define XPAR_INTC_SINGLE_DEVICE_ID XPAR_XPS_INTC_0_DEVICE_ID
#define XPAR_D_USB_EPP_DSTM_0_IRQ_EPP_MASK 0X000001
#define XPAR_XPS_INTC_0_D_USB_EPP_DSTM_0_IRQ_EPP_INTR 0
#define XPAR_D_USB_EPP_DSTM_0_IRQ_DSTM_MASK 0X000002
#define XPAR_XPS_INTC_0_D_USB_EPP_DSTM_0_IRQ_DSTM_INTR 1
#define XPAR_PS2_KEYBOARD_MOUSE_IP2INTC_IRPT_2_MASK 0X000004
#define XPAR_XPS_INTC_0_PS2_KEYBOARD_MOUSE_IP2INTC_IRPT_2_INTR 2
#define XPAR_PS2_KEYBOARD_MOUSE_IP2INTC_IRPT_1_MASK 0X000008
#define XPAR_XPS_INTC_0_PS2_KEYBOARD_MOUSE_IP2INTC_IRPT_1_INTR 3
#define XPAR_SOFT_TEMAC_TEMACINTC0_IRPT_MASK 0X000010
#define XPAR_XPS_INTC_0_SOFT_TEMAC_TEMACINTC0_IRPT_INTR 4
#define XPAR_MCB_DDR2_SDMA1_TX_INTOUT_MASK 0X000020
#define XPAR_XPS_INTC_0_MCB_DDR2_SDMA1_TX_INTOUT_INTR 5
#define XPAR_MCB_DDR2_SDMA1_RX_INTOUT_MASK 0X000040
#define XPAR_XPS_INTC_0_MCB_DDR2_SDMA1_RX_INTOUT_INTR 6

/******************************************************************/

/* Canonical definitions for peripheral XPS_INTC_0 */
#define XPAR_INTC_0_DEVICE_ID XPAR_XPS_INTC_0_DEVICE_ID
#define XPAR_INTC_0_BASEADDR 0x81800000
#define XPAR_INTC_0_HIGHADDR 0x8180FFFF
#define XPAR_INTC_0_KIND_OF_INTR 0xFFFFFF80

#define XPAR_INTC_0_D_USB_EPP_DSTM_0_IRQ_EPP_VEC_ID XPAR_XPS_INTC_0_D_USB_EPP_DSTM_0_IRQ_EPP_INTR
#define XPAR_INTC_0_D_USB_EPP_DSTM_0_IRQ_DSTM_VEC_ID XPAR_XPS_INTC_0_D_USB_EPP_DSTM_0_IRQ_DSTM_INTR
#define XPAR_INTC_0_PS2_0_IP2INTC_IRPT_2_VEC_ID XPAR_XPS_INTC_0_PS2_KEYBOARD_MOUSE_IP2INTC_IRPT_2_INTR
#define XPAR_INTC_0_PS2_0_IP2INTC_IRPT_1_VEC_ID XPAR_XPS_INTC_0_PS2_KEYBOARD_MOUSE_IP2INTC_IRPT_1_INTR
#define XPAR_INTC_0_LLTEMAC_0_VEC_ID XPAR_XPS_INTC_0_SOFT_TEMAC_TEMACINTC0_IRPT_INTR
#define XPAR_INTC_0_MPMC_0_SDMA1_TX_INTOUT_VEC_ID XPAR_XPS_INTC_0_MCB_DDR2_SDMA1_TX_INTOUT_INTR
#define XPAR_INTC_0_MPMC_0_SDMA1_RX_INTOUT_VEC_ID XPAR_XPS_INTC_0_MCB_DDR2_SDMA1_RX_INTOUT_INTR

/******************************************************************/

/* Definitions for driver UARTNS550 */
#define XPAR_XUARTNS550_NUM_INSTANCES 1
#define XPAR_XUARTNS550_CLOCK_HZ 66666666

/* Definitions for peripheral XPS_UART16550_0 */
#define XPAR_XPS_UART16550_0_DEVICE_ID 0
#define XPAR_XPS_UART16550_0_BASEADDR 0x83E00000
#define XPAR_XPS_UART16550_0_HIGHADDR 0x83E0FFFF
#define XPAR_XPS_UART16550_0_CLOCK_FREQ_HZ 66666666


/******************************************************************/

/* Canonical definitions for peripheral XPS_UART16550_0 */
#define XPAR_UARTNS550_0_DEVICE_ID XPAR_XPS_UART16550_0_DEVICE_ID
#define XPAR_UARTNS550_0_BASEADDR 0x83E00000
#define XPAR_UARTNS550_0_HIGHADDR 0x83E0FFFF
#define XPAR_UARTNS550_0_CLOCK_FREQ_HZ XPAR_XPS_UART16550_0_CLOCK_FREQ_HZ
#define XPAR_UARTNS550_0_SIO_CHAN -1


/******************************************************************/

/* Definitions for bus frequencies */
#define XPAR_CPU_DPLB_FREQ_HZ 66666666
#define XPAR_CPU_IPLB_FREQ_HZ 66666666
/******************************************************************/

/* Canonical definitions for bus frequencies */
#define XPAR_PROC_BUS_0_FREQ_HZ 66666666
/******************************************************************/

#define XPAR_CPU_CORE_CLOCK_FREQ_HZ 66666666
#define XPAR_MICROBLAZE_CORE_CLOCK_FREQ_HZ 66666666

/******************************************************************/


/* Definitions for peripheral MICROBLAZE_0 */
#define XPAR_MICROBLAZE_0_SCO 0
#define XPAR_MICROBLAZE_0_FREQ 66666666
#define XPAR_MICROBLAZE_0_DATA_SIZE 32
#define XPAR_MICROBLAZE_0_DYNAMIC_BUS_SIZING 1
#define XPAR_MICROBLAZE_0_AREA_OPTIMIZED 0
#define XPAR_MICROBLAZE_0_OPTIMIZATION 0
#define XPAR_MICROBLAZE_0_INTERCONNECT 1
#define XPAR_MICROBLAZE_0_DPLB_DWIDTH 32
#define XPAR_MICROBLAZE_0_DPLB_NATIVE_DWIDTH 32
#define XPAR_MICROBLAZE_0_DPLB_BURST_EN 0
#define XPAR_MICROBLAZE_0_DPLB_P2P 0
#define XPAR_MICROBLAZE_0_IPLB_DWIDTH 32
#define XPAR_MICROBLAZE_0_IPLB_NATIVE_DWIDTH 32
#define XPAR_MICROBLAZE_0_IPLB_BURST_EN 0
#define XPAR_MICROBLAZE_0_IPLB_P2P 0
#define XPAR_MICROBLAZE_0_D_PLB 1
#define XPAR_MICROBLAZE_0_D_LMB 1
#define XPAR_MICROBLAZE_0_I_PLB 1
#define XPAR_MICROBLAZE_0_I_LMB 1
#define XPAR_MICROBLAZE_0_USE_MSR_INSTR 1
#define XPAR_MICROBLAZE_0_USE_PCMP_INSTR 1
#define XPAR_MICROBLAZE_0_USE_BARREL 0
#define XPAR_MICROBLAZE_0_USE_DIV 0
#define XPAR_MICROBLAZE_0_USE_HW_MUL 1
#define XPAR_MICROBLAZE_0_USE_FPU 0
#define XPAR_MICROBLAZE_0_UNALIGNED_EXCEPTIONS 0
#define XPAR_MICROBLAZE_0_ILL_OPCODE_EXCEPTION 0
#define XPAR_MICROBLAZE_0_IPLB_BUS_EXCEPTION 0
#define XPAR_MICROBLAZE_0_DPLB_BUS_EXCEPTION 0
#define XPAR_MICROBLAZE_0_DIV_ZERO_EXCEPTION 0
#define XPAR_MICROBLAZE_0_FPU_EXCEPTION 0
#define XPAR_MICROBLAZE_0_FSL_EXCEPTION 0
#define XPAR_MICROBLAZE_0_PVR 0
#define XPAR_MICROBLAZE_0_PVR_USER1 0x00
#define XPAR_MICROBLAZE_0_PVR_USER2 0x00000000
#define XPAR_MICROBLAZE_0_DEBUG_ENABLED 1
#define XPAR_MICROBLAZE_0_NUMBER_OF_PC_BRK 1
#define XPAR_MICROBLAZE_0_NUMBER_OF_RD_ADDR_BRK 0
#define XPAR_MICROBLAZE_0_NUMBER_OF_WR_ADDR_BRK 0
#define XPAR_MICROBLAZE_0_INTERRUPT_IS_EDGE 0
#define XPAR_MICROBLAZE_0_EDGE_IS_POSITIVE 1
#define XPAR_MICROBLAZE_0_RESET_MSR 0x00000000
#define XPAR_MICROBLAZE_0_OPCODE_0X0_ILLEGAL 0
#define XPAR_MICROBLAZE_0_FSL_LINKS 0
#define XPAR_MICROBLAZE_0_FSL_DATA_SIZE 32
#define XPAR_MICROBLAZE_0_USE_EXTENDED_FSL_INSTR 0
#define XPAR_MICROBLAZE_0_ICACHE_BASEADDR 0x48000000
#define XPAR_MICROBLAZE_0_ICACHE_HIGHADDR 0x4FFFFFFF
#define XPAR_MICROBLAZE_0_USE_ICACHE 1
#define XPAR_MICROBLAZE_0_ALLOW_ICACHE_WR 1
#define XPAR_MICROBLAZE_0_ADDR_TAG_BITS 16
#define XPAR_MICROBLAZE_0_CACHE_BYTE_SIZE 2048
#define XPAR_MICROBLAZE_0_ICACHE_USE_FSL 1
#define XPAR_MICROBLAZE_0_ICACHE_LINE_LEN 4
#define XPAR_MICROBLAZE_0_ICACHE_ALWAYS_USED 1
#define XPAR_MICROBLAZE_0_ICACHE_INTERFACE 0
#define XPAR_MICROBLAZE_0_ICACHE_VICTIMS 0
#define XPAR_MICROBLAZE_0_ICACHE_STREAMS 0
#define XPAR_MICROBLAZE_0_DCACHE_BASEADDR 0x48000000
#define XPAR_MICROBLAZE_0_DCACHE_HIGHADDR 0x4FFFFFFF
#define XPAR_MICROBLAZE_0_USE_DCACHE 1
#define XPAR_MICROBLAZE_0_ALLOW_DCACHE_WR 1
#define XPAR_MICROBLAZE_0_DCACHE_ADDR_TAG 16
#define XPAR_MICROBLAZE_0_DCACHE_BYTE_SIZE 2048
#define XPAR_MICROBLAZE_0_DCACHE_USE_FSL 1
#define XPAR_MICROBLAZE_0_DCACHE_LINE_LEN 4
#define XPAR_MICROBLAZE_0_DCACHE_ALWAYS_USED 1
#define XPAR_MICROBLAZE_0_DCACHE_INTERFACE 0
#define XPAR_MICROBLAZE_0_DCACHE_USE_WRITEBACK 0
#define XPAR_MICROBLAZE_0_DCACHE_VICTIMS 0
#define XPAR_MICROBLAZE_0_USE_MMU 0
#define XPAR_MICROBLAZE_0_MMU_DTLB_SIZE 4
#define XPAR_MICROBLAZE_0_MMU_ITLB_SIZE 2
#define XPAR_MICROBLAZE_0_MMU_TLB_ACCESS 3
#define XPAR_MICROBLAZE_0_MMU_ZONES 16
#define XPAR_MICROBLAZE_0_USE_INTERRUPT 1
#define XPAR_MICROBLAZE_0_USE_EXT_BRK 1
#define XPAR_MICROBLAZE_0_USE_EXT_NM_BRK 1
#define XPAR_MICROBLAZE_0_USE_BRANCH_TARGET_CACHE 0
#define XPAR_MICROBLAZE_0_BRANCH_TARGET_CACHE_SIZE 0

/******************************************************************/

#define XPAR_CPU_ID 0
#define XPAR_MICROBLAZE_ID 0
#define XPAR_MICROBLAZE_SCO 0
#define XPAR_MICROBLAZE_FREQ 66666666
#define XPAR_MICROBLAZE_DATA_SIZE 32
#define XPAR_MICROBLAZE_DYNAMIC_BUS_SIZING 1
#define XPAR_MICROBLAZE_AREA_OPTIMIZED 0
#define XPAR_MICROBLAZE_OPTIMIZATION 0
#define XPAR_MICROBLAZE_INTERCONNECT 1
#define XPAR_MICROBLAZE_DPLB_DWIDTH 32
#define XPAR_MICROBLAZE_DPLB_NATIVE_DWIDTH 32
#define XPAR_MICROBLAZE_DPLB_BURST_EN 0
#define XPAR_MICROBLAZE_DPLB_P2P 0
#define XPAR_MICROBLAZE_IPLB_DWIDTH 32
#define XPAR_MICROBLAZE_IPLB_NATIVE_DWIDTH 32
#define XPAR_MICROBLAZE_IPLB_BURST_EN 0
#define XPAR_MICROBLAZE_IPLB_P2P 0
#define XPAR_MICROBLAZE_D_PLB 1
#define XPAR_MICROBLAZE_D_LMB 1
#define XPAR_MICROBLAZE_I_PLB 1
#define XPAR_MICROBLAZE_I_LMB 1
#define XPAR_MICROBLAZE_USE_MSR_INSTR 1
#define XPAR_MICROBLAZE_USE_PCMP_INSTR 1
#define XPAR_MICROBLAZE_USE_BARREL 0
#define XPAR_MICROBLAZE_USE_DIV 0
#define XPAR_MICROBLAZE_USE_HW_MUL 1
#define XPAR_MICROBLAZE_USE_FPU 0
#define XPAR_MICROBLAZE_UNALIGNED_EXCEPTIONS 0
#define XPAR_MICROBLAZE_ILL_OPCODE_EXCEPTION 0
#define XPAR_MICROBLAZE_IPLB_BUS_EXCEPTION 0
#define XPAR_MICROBLAZE_DPLB_BUS_EXCEPTION 0
#define XPAR_MICROBLAZE_DIV_ZERO_EXCEPTION 0
#define XPAR_MICROBLAZE_FPU_EXCEPTION 0
#define XPAR_MICROBLAZE_FSL_EXCEPTION 0
#define XPAR_MICROBLAZE_PVR 0
#define XPAR_MICROBLAZE_PVR_USER1 0x00
#define XPAR_MICROBLAZE_PVR_USER2 0x00000000
#define XPAR_MICROBLAZE_DEBUG_ENABLED 1
#define XPAR_MICROBLAZE_NUMBER_OF_PC_BRK 1
#define XPAR_MICROBLAZE_NUMBER_OF_RD_ADDR_BRK 0
#define XPAR_MICROBLAZE_NUMBER_OF_WR_ADDR_BRK 0
#define XPAR_MICROBLAZE_INTERRUPT_IS_EDGE 0
#define XPAR_MICROBLAZE_EDGE_IS_POSITIVE 1
#define XPAR_MICROBLAZE_RESET_MSR 0x00000000
#define XPAR_MICROBLAZE_OPCODE_0X0_ILLEGAL 0
#define XPAR_MICROBLAZE_FSL_LINKS 0
#define XPAR_MICROBLAZE_FSL_DATA_SIZE 32
#define XPAR_MICROBLAZE_USE_EXTENDED_FSL_INSTR 0
#define XPAR_MICROBLAZE_ICACHE_BASEADDR 0x48000000
#define XPAR_MICROBLAZE_ICACHE_HIGHADDR 0x4FFFFFFF
#define XPAR_MICROBLAZE_USE_ICACHE 1
#define XPAR_MICROBLAZE_ALLOW_ICACHE_WR 1
#define XPAR_MICROBLAZE_ADDR_TAG_BITS 16
#define XPAR_MICROBLAZE_CACHE_BYTE_SIZE 2048
#define XPAR_MICROBLAZE_ICACHE_USE_FSL 1
#define XPAR_MICROBLAZE_ICACHE_LINE_LEN 4
#define XPAR_MICROBLAZE_ICACHE_ALWAYS_USED 1
#define XPAR_MICROBLAZE_ICACHE_INTERFACE 0
#define XPAR_MICROBLAZE_ICACHE_VICTIMS 0
#define XPAR_MICROBLAZE_ICACHE_STREAMS 0
#define XPAR_MICROBLAZE_DCACHE_BASEADDR 0x48000000
#define XPAR_MICROBLAZE_DCACHE_HIGHADDR 0x4FFFFFFF
#define XPAR_MICROBLAZE_USE_DCACHE 1
#define XPAR_MICROBLAZE_ALLOW_DCACHE_WR 1
#define XPAR_MICROBLAZE_DCACHE_ADDR_TAG 16
#define XPAR_MICROBLAZE_DCACHE_BYTE_SIZE 2048
#define XPAR_MICROBLAZE_DCACHE_USE_FSL 1
#define XPAR_MICROBLAZE_DCACHE_LINE_LEN 4
#define XPAR_MICROBLAZE_DCACHE_ALWAYS_USED 1
#define XPAR_MICROBLAZE_DCACHE_INTERFACE 0
#define XPAR_MICROBLAZE_DCACHE_USE_WRITEBACK 0
#define XPAR_MICROBLAZE_DCACHE_VICTIMS 0
#define XPAR_MICROBLAZE_USE_MMU 0
#define XPAR_MICROBLAZE_MMU_DTLB_SIZE 4
#define XPAR_MICROBLAZE_MMU_ITLB_SIZE 2
#define XPAR_MICROBLAZE_MMU_TLB_ACCESS 3
#define XPAR_MICROBLAZE_MMU_ZONES 16
#define XPAR_MICROBLAZE_USE_INTERRUPT 1
#define XPAR_MICROBLAZE_USE_EXT_BRK 1
#define XPAR_MICROBLAZE_USE_EXT_NM_BRK 1
#define XPAR_MICROBLAZE_USE_BRANCH_TARGET_CACHE 0
#define XPAR_MICROBLAZE_BRANCH_TARGET_CACHE_SIZE 0
#define XPAR_MICROBLAZE_HW_VER "7.30.b"

/******************************************************************/

