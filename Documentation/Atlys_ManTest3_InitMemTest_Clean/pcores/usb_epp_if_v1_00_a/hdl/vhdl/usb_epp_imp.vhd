------------------------------------------------------------------------------
-- user_logic.vhd - entity/architecture pair
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2009 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          user_logic.vhd
-- Version:           1.00.a
-- Description:       User logic.
-- Date:              Thu Aug 27 17:11:15 2009 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

-- DO NOT EDIT BELOW THIS LINE --------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

-- DO NOT EDIT ABOVE THIS LINE --------------------

--USER libraries added here

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--   C_NUM_REG                    -- Number of software accessible registers
--
-- Definition of Ports:
--   Bus2IP_Clk                   -- Bus to IP clock
--   Bus2IP_Reset                 -- Bus to IP reset
--   Bus2IP_Data                  -- Bus to IP data bus
--   Bus2IP_BE                    -- Bus to IP byte enables
--   Bus2IP_RdCE                  -- Bus to IP read chip enable
--   Bus2IP_WrCE                  -- Bus to IP write chip enable
--   IP2Bus_Data                  -- IP to Bus data bus
--   IP2Bus_RdAck                 -- IP to Bus read transfer acknowledgement
--   IP2Bus_WrAck                 -- IP to Bus write transfer acknowledgement
--   IP2Bus_Error                 -- IP to Bus error response
------------------------------------------------------------------------------

entity usb_epp_imp is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    C_NUM_USER_REGS                 : integer := 32;
    C_PLB_CLK_TO_SPL_RATE_RATIO     : integer := 5;
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_SLV_DWIDTH                   : integer              := 32;
    C_NUM_REG                      : integer              := 4
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
    DB_O                    : out std_logic_vector (0 to 7);--Data Output port
    DB_I                    : in std_logic_vector (0 to 7);-- Data Input port
    DB_T                    : out std_logic;  -- OBUT enable signal for data bus
    EPP_write               : in std_logic; -- write signal from the EPP bus
    ASTB                    : in std_logic; -- Adress strobe signal from the EPP bus
    DSTB                    : in std_logic; -- Data strobe signal from the EPP bus
    BUSY                    : out std_logic; -- Adress strobe signal from the EPP bus
    EPP_Irpt		    : out std_logic; -- Activated when an EPP transaction has begin
    INT_USB                 : out std_logic; -- Interrupt signal to the EPP controller
                                             -- will not be used in this project
    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    Bus2IP_Clk                     : in  std_logic;
    Bus2IP_Reset                   : in  std_logic;
    Bus2IP_Data                    : in  std_logic_vector(0 to C_SLV_DWIDTH-1);
    Bus2IP_BE                      : in  std_logic_vector(0 to C_SLV_DWIDTH/8-1);
    Bus2IP_RdCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
    Bus2IP_WrCE                    : in  std_logic_vector(0 to C_NUM_REG-1);
    IP2Bus_Data                    : out std_logic_vector(0 to C_SLV_DWIDTH-1);
    IP2Bus_RdAck                   : out std_logic;
    IP2Bus_WrAck                   : out std_logic;
    IP2Bus_Error                   : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute SIGIS : string;
  attribute SIGIS of Bus2IP_Clk    : signal is "CLK";
  attribute SIGIS of Bus2IP_Reset  : signal is "RST";

end entity usb_epp_imp;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of usb_epp_imp is

  --USER signal declarations added here, as needed for user logic
  -- function used to calculate the number of bits needed to represent an integer
   -- This will be used to avoid reading higher address values than the number of user registers
   function calcnumbits (Value: integer) return integer is
      variable i, j: integer range 0 to 32:=1;
      variable Val_out: integer:=0;
   begin
         j:=0;
         if Value=0 or Value=1 then return 1;
         else
            for i in 1 to 32 loop
             if Val_out >= Value then null;
             else 
                Val_out:= 2 ** i; 
                j:=j+1;
             end if;
            end loop;
            return j;
         end if;
   end calcnumbits;
  
  --function used to determine the position of the first active '1' bit in a vector
  -- will be used to determine the read and/or write address
  -- works with big endian vectors
  function position (Input: std_logic_vector; size: integer) return integer is
  variable i, j: integer:=0;
  begin
   j:=0;
   for i in 0 to size-1 loop
     if Input(j)='1' then exit;
     else j:=j+1;
     end if;
   end loop;
   if j=size then return 0;
   else return j;
   end if;
  end position;
  
   -- State machine definition
constant  Idle                : std_logic_vector(13 downto 0) := "0000" & "0001"&"0000"&"00"; -- Do nothing
constant  RnW_Addr            : std_logic_vector(13 downto 0) := "0001" & "1001"&"0000"&"00"; -- Enter into an Address Read or Write cycle
constant  RnW_Data            : std_logic_vector(13 downto 0) := "1000" & "1001"&"0010"&"00"; -- Enter into a Data Read or Write cycle
constant  Read_Addr           : std_logic_vector(13 downto 0) := "0011" & "1001"&"0100"&"00"; -- Read the adress from the EPP
constant  Wait_on_Astb_Write  : std_logic_vector(13 downto 0) := "0111" & "1001"&"0000"&"01"; -- wait until ASTB is reasserted in a write cycle
constant  Send_Addr           : std_logic_vector(13 downto 0) := "0101" & "1000"&"1000"&"00"; -- Send the adress register content to the data bus
constant  Wait_on_Astb_Read   : std_logic_vector(13 downto 0) := "1101" & "1000"&"0000"&"01"; -- wait until ASTB is reasserted in a read cycle
constant  Read_Data           : std_logic_vector(13 downto 0) := "1100" & "1011"&"0001"&"00"; -- Read the data from the EPP
constant  Wait_on_Isr_Write   : std_logic_vector(13 downto 0) := "1110" & "1011"&"0000"&"10"; -- Wait until the PLB bus is servicing the interrupt generated
                                                                                           -- by the EPP_USB interface on a write cycle 
constant  Wait_on_Dstb_Write  : std_logic_vector(13 downto 0) := "0110" & "1001"&"0000"&"01"; -- Wait until DSTB is reasserted in a write cycle
constant  Wait_on_Isr_Read    : std_logic_vector(13 downto 0) := "1010" & "1101"&"0000"&"10"; -- Wait until the PLB bus is servicing the interrupt generated
                                                                                           -- by the EPP_USB interface on a read cycle
constant  Send_Data           : std_logic_vector(13 downto 0) := "1011" & "1100"&"0000"&"00"; -- Send the datas register content to the data bus
constant  Wait_on_Dstb_Read   : std_logic_vector(13 downto 0) := "1111" & "1000"&"0000"&"01"; -- wait until DSTB is reasserted in a read cycle
--constant  Done1               : std_logic_vector(13 downto 0) := "0010" & "0001"&"0000"&"00"; -- Illegal state
--constant  Done2               : std_logic_vector(13 downto 0) := "1001" & "0001"&"0000"&"00"; -- Illegal state
constant  Done                : std_logic_vector(13 downto 0) := "0100" & "0001"&"0000"&"00"; -- State machine finish state

  signal NEXTSTATE, STATE : std_logic_vector (13 downto 0):=Idle;
  
  attribute FSM_ENCODING : string;
  attribute FSM_ENCODING of STATE: signal is "USER";
  
  attribute SAFE_IMPLEMENTATION: string;
  attribute SAFE_IMPLEMENTATION of STATE: signal is "YES";
  
  signal STATE_DBG: std_logic_vector (0 to 3):="0000";
  
  --array for user registers - RAM
  constant MEMSIZE: integer := C_NUM_USER_REGS;--(2 ** (calcnumbits (C_NUM_USER_REGS-1)));
  --constant MEM_ADDR_SIZE: integer := calcnumbits (C_NUM_USER_REGS-1);
  
  -- used to reduce address register write to the number of bits required
  -- to adress the user registers
  constant bit_num_user_regs: integer := calcnumbits (C_NUM_USER_REGS-1);
  
  type user_reg_array is   array (MEMSIZE - 1 downto 0) of std_logic_vector(0 to 7);
  signal user_data_regs_RAM: user_reg_array:=(others => (others =>'0'));
  -- user data register to write to RAM
  signal user_write_RAM_reg             : std_logic_vector(0 to 7):=(others => '0');
  -- user data register to read from 
  signal user_read_RAM_reg              : std_logic_vector(0 to 7):=(others => '0');
  -- update the data_reg if an address write is performed from the processor
  signal update_data_reg					 : std_logic:='0';
  -- delay one clock cycle the update_data_reg signal
  signal update_data_reg_del				 : std_logic_vector(1 downto 0) :="00";
  -- RAM write enable signal from the state machine
  signal user_RAM_WE                    : std_logic:='0';
  -- RAM write enable signal from the state PLB bus
  signal user_RAM_WE_PLB                : std_logic:='0';  
  -- Enable to update the address register
  signal Update_Addr_Reg                : std_logic:='0';
  -- Enable to send the content of the address register instead of the data register
  signal EN_ADDR_OUT                    : std_logic:='0';
  -- RAM address read and write registers
  --signal user_RAM_WRITE_ADDR            : std_logic_vector(MEM_ADDR_SIZE-1 downto 0):=(others => '0');
  --signal user_RAM_WRITE_ADDR_reg        : std_logic_vector(MEM_ADDR_SIZE-1 downto 0):=(others => '0');
  --signal user_RAM_READ_ADDR             : std_logic_vector(MEM_ADDR_SIZE-1 downto 0):=(others => '0');
  
  --signal user_reg_write_select          : std_logic_vector(0 to 3):=(others => '0');--user data register write select
  --signal user_reg_read_select           : std_logic_vector(0 to 3):=(others => '0');----adress register read select

  -- Slave write acknowledge will be delayed with one clock cycle from slv_write_ack,
  -- because the data written in the user register will be written on the next clock cycle
  -- into the RAM
  signal slv_write_ack_reg                  : std_logic;
  -- Delay slv_write_ack_reg with one clock cycle when acknowledging EPP reads from the PLB bus
  -- to insure that the data already written in the register will be sent on the EPP bus
  signal slv_write_ack_reg1                 : std_logic:='0';

  -- EPP state machine status register bits
  signal Write_Performed                    : std_logic:='0';
  signal Read_Requested                     : std_logic:='0';
  signal EPP_Performing                     : std_logic:='0';
  -- Enable to read from the data bus
  signal En_Read_Data_Bus                   : std_logic:='0';
   
  -- signal asserted when the PLB bus performs a read operation from the memory location corresponding
  -- with the value in the address register. To prevent data loss in a data write cycle, 
  -- the state machine will deassert the BUSY signal only after the PLB bus reads the corresponding register
  signal c_reg_read                     : std_logic:='0';
  -- signal asserted when the PLB bus performs a write operation to the register corresponding
  -- with the value in the address register. At the beginning of a data read cycle, 
  -- the state machine sends the data and asserts the BUSY signal only after PLB bus writes to the corresponding register
  signal c_reg_write                    : std_logic:='0';

  -- Delay c_reg_write with two clock cycles when acknowledging EPP reads from the PLB bus
  -- to insure that the data already written in the register will be sent on the EPP bus
  signal c_reg_write_reg							: std_logic:='0';
  signal c_reg_write_reg1                    : std_logic:='0';

  -- synchronize and debounce the ASTB, DSTB and EPP_WRITE_REG signals
  --signal db_astb_up, db_astb_dn, db_astb_q0, db_astb_q1, db_astb_q2: std_logic:='0';
  --signal db_dstb_up, db_dstb_dn, db_dstb_q0, db_dstb_q1, db_dstb_q2: std_logic:='0';
  signal ASTB_REG, DSTB_REG, EPP_WRITE_REG: std_logic_vector (1 downto 0):="00";

  -- Reform the DSTB signal, because the EPP port can answer earlier than the OPB interface
  --signal db_dstb: std_logic;
 

  -- internal combinational signals that will be registered for the outputs
  --signal DB_O_CMB : std_logic_vector (0 to 7);
  --signal BUSY_CMB : std_logic;

  -- divide the system clock to obtain the sample rate for the signals
  signal div_sample_rate: integer range 0 to C_PLB_CLK_TO_SPL_RATE_RATIO-1;
  signal CE_SAMPLE_RATE: std_logic;

  ------------------------------------------
  -- Signals for user logic slave model s/w accessible register example
  ------------------------------------------
  signal data_reg                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal address_reg                    : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal status_reg                     : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg3                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg_write_sel              : std_logic_vector(0 to 3);
  signal slv_reg_read_sel               : std_logic_vector(0 to 3);
  signal slv_ip2bus_data                : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_read_ack                   : std_logic;
  signal slv_write_ack                  : std_logic;

begin

  --USER logic implementation added here

  ------------------------------------------
  -- Example code to read/write user logic slave model s/w accessible registers
  -- 
  -- Note:
  -- The example code presented here is to show you one way of reading/writing
  -- software accessible registers implemented in the user logic slave model.
  -- Each bit of the Bus2IP_WrCE/Bus2IP_RdCE signals is configured to correspond
  -- to one software accessible register by the top level template. For example,
  -- if you have four 32 bit software accessible registers in the user logic,
  -- you are basically operating on the following memory mapped registers:
  -- 
  --    Bus2IP_WrCE/Bus2IP_RdCE   Memory Mapped Register
  --                     "1000"   C_BASEADDR + 0x0
  --                     "0100"   C_BASEADDR + 0x4
  --                     "0010"   C_BASEADDR + 0x8
  --                     "0001"   C_BASEADDR + 0xC
  -- 

BUSY              <= STATE (0);
EPP_IRPT          <= STATE (1);
user_RAM_WE       <= STATE (2);
En_Read_Data_Bus  <= STATE (3);
Update_Addr_Reg   <= STATE (4);
EN_ADDR_OUT       <= STATE (5);
DB_T              <= STATE (6);
Write_Performed   <= STATE (7);
Read_Requested    <= STATE (8);
EPP_Performing    <= STATE (9);
  
-- divide to obtain the sample rate
divide: process (Bus2IP_Clk, BUs2IP_Reset, div_sample_rate) is
begin
    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if BUs2IP_Reset = '1' OR div_sample_rate = (C_PLB_CLK_TO_SPL_RATE_RATIO-1) then
         div_sample_rate <= 0;
      else
         div_sample_rate <= div_sample_rate + 1;
      end if;
    end if;
end process divide;

CE_SAMPLE_RATE <= '1' when div_sample_rate = (C_PLB_CLK_TO_SPL_RATE_RATIO-1) else '0';

    -----------------------------------------------------
  -- debounce and synchronize ASTB and WRSTB signals
  -----------------------------------------------------
--debounce: process (Bus2IP_Clk, CE_SAMPLE_RATE, ASTB, DSTB, db_astb_q0, db_astb_q1, db_dstb_q0, db_dstb_q1)
--begin
--    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
--      if CE_SAMPLE_RATE = '1' then
--         db_astb_q0<=ASTB; db_astb_q1<=db_astb_q0; 
--         db_dstb_q0<=DSTB; db_dstb_q1<=db_dstb_q0;
--      end if;
--         db_astb_q2<=db_astb_q1;
--         db_dstb_q2<=db_dstb_q1;
--    end if;
--end process debounce;
--
--db_astb_up <= (db_astb_q0 AND db_astb_q1) AND ( NOT db_astb_q2);
--db_astb_dn <= (db_astb_q0 NOR db_astb_q1) AND ( db_astb_q2 );
--db_dstb_up <= (db_dstb_q0 AND db_dstb_q1) AND ( NOT db_dstb_q2);
--db_dstb_dn <= (db_dstb_q0 NOR db_dstb_q1) AND ( db_dstb_q2 );

--register the ASTB and DSTB signals
reg_ASTB_DSTB: process (Bus2IP_Clk, CE_SAMPLE_RATE, ASTB, DSTB, EPP_Write, 
                        ASTB_REG, DSTB_REG, EPP_WRITE_REG) is
begin
    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if CE_SAMPLE_RATE = '1' then
         ASTB_REG(1 downto 0) <= ASTB_REG(0) & ASTB;
         DSTB_REG(1 downto 0) <= DSTB_REG(0) & DSTB;
         EPP_write_reg (1 downto 0) <= EPP_write_reg(0) & EPP_write;
      end if;
    end if;
end process reg_ASTB_DSTB;



--delay_signals: process(Bus2IP_Clk, db_dstb_up_reg, db_dstb_dn_reg, db_astb_up_reg, db_astb_dn_reg,
--                       db_astb_up, db_astb_dn, db_dstb_up, db_dstb_dn)
--begin
--    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
--         db_dstb_up_reg(2 downto 0) <= db_dstb_up_reg (1 downto 0) & db_dstb_up;
--         db_astb_up_reg(2 downto 0) <= db_astb_up_reg (1 downto 0) & db_astb_up;
--         db_dstb_dn_reg(2 downto 0) <= db_dstb_dn_reg (1 downto 0) & db_dstb_dn;
--         db_astb_dn_reg(2 downto 0) <= db_astb_dn_reg (1 downto 0) & db_astb_dn;
--    end if;
--end process delay_signals;

-- Reform the ASTB and DSTB signals

--reform_signals: process (Bus2IP_Clk, db_dstb_up, db_dstb_dn)
--begin
--    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
--      db_dstb <= '0';
--		if db_dstb_up='1' then
--         db_dstb<='1';      
--      elsif db_dstb_dn='1' then
--         db_dstb<='1';      
--      end if;
--    end if;
--end process reform_signals;

  -----------------------------------------------------
  -- State machine registerred process
  -----------------------------------------------------
reg_states: process(Bus2IP_Clk, BUs2IP_Reset, NEXTSTATE)
begin
   if Bus2IP_Clk'event and BUs2IP_Clk='1' then
      if BUs2IP_Reset = '1' then
         STATE<=Idle;
      else STATE<=NEXTSTATE; end if;
   end if;
end process reg_states;

  -----------------------------------------------------
  -- State machine transitions process
  -----------------------------------------------------
tranz_states: process (STATE, ASTB_REG, DSTB_REG, EPP_write_reg, c_reg_read, c_reg_write_reg1, slv_write_ack_reg1) is
begin
   -- default: Stay in the current state
   NEXTSTATE<=STATE;
   case STATE is
       when   Idle           =>  if    ASTB_REG(1)='0' then NEXTSTATE<= RnW_Addr;
                                 elsif DSTB_REG(1)='0' then NEXTSTATE<= RnW_Data;
                                 end if;
       when   RnW_Addr       =>  if EPP_write_reg (1) = '0' then NEXTSTATE <= Read_Addr;
                                 else  NEXTSTATE <= Send_Addr;
                                 end if;
       when   RnW_Data       =>  if EPP_write_reg(1) = '0' then NEXTSTATE <= Read_Data;
                                 else  NEXTSTATE <= Wait_on_Isr_Read;
                                 end if;
       when   Read_Addr		  =>  NEXTSTATE <= Wait_on_Astb_Write;
       
       when   Wait_on_Astb_Write  => if ASTB_REG(1)='1' then NEXTSTATE <= Done; 
                                     end if;
       when   Send_Addr		  => NEXTSTATE <= Wait_on_Astb_Read;
       
       when   Wait_on_Astb_Read	 => if ASTB_REG(1) = '1' then NEXTSTATE <= Done; 
                                     end if;
       when   Read_Data		  => NEXTSTATE <= Wait_on_Isr_Write;
       
       when   Wait_on_Isr_Write	  => if c_reg_read='1' then NEXTSTATE <= Wait_on_Dstb_Write;
                                      end if;
       when   Wait_on_Dstb_Write   => if DSTB_REG(1)='1' then NEXTSTATE <= Done;
                                      end if;
       when   Wait_on_Isr_Read	  => if c_reg_write_reg1='1' and slv_write_ack_reg1='1' then NEXTSTATE <= Send_Data;
                                      end if;
       when   Send_Data		  => NEXTSTATE <= Wait_on_Dstb_Read;

       when   Wait_on_Dstb_Read   =>  if DSTB_REG(1)='1' then NEXTSTATE <= Done;
                                      end if;
       when   Done  => NEXTSTATE<=Idle;
       
--       when   Done1 => NEXTSTATE<=Idle;
       
--       when   Done2 =>  NEXTSTATE<=Idle;
       
       when others => NEXTSTATE<=Idle;
   end case;
end process tranz_states;
 
  
  ------------------------------------------
  slv_reg_write_sel <= Bus2IP_WrCE(0 to 3);
  slv_reg_read_sel  <= Bus2IP_RdCE(0 to 3);
  slv_write_ack     <= Bus2IP_WrCE(0) or Bus2IP_WrCE(1) or Bus2IP_WrCE(2) or Bus2IP_WrCE(3);
  slv_read_ack      <= Bus2IP_RdCE(0) or Bus2IP_RdCE(1) or Bus2IP_RdCE(2) or Bus2IP_RdCE(3);

-- register slv_write_ack
register_slv_write_ack: process (Bus2IP_Clk, slv_write_ack, slv_write_ack_reg)
begin
   if Bus2IP_Clk'Event and Bus2IP_Clk='1' then
      slv_write_ack_reg<=slv_write_ack;
      slv_write_ack_reg1<=slv_write_ack_reg;
   end if;
end process register_slv_write_ack;
 -----------------------------------------------------
  -- assign the c_reg_read and c_reg_write signals
  -----------------------------------------------------

c_reg_read <= '1' when Bus2IP_RdCE(0) = '1' 
                and address_reg(C_SLV_DWIDTH-8 to C_SLV_DWIDTH-1) = status_reg(C_SLV_DWIDTH-8 to C_SLV_DWIDTH-1)
					 else '0';

c_reg_write <= '1' when Bus2IP_WrCE(0) = '1' 
                and address_reg(C_SLV_DWIDTH-8 to C_SLV_DWIDTH-1) = status_reg(C_SLV_DWIDTH-8 to C_SLV_DWIDTH-1)
					 else '0';

-- delay c_reg_write with one clock cycle
register_c_reg_write: process (Bus2IP_Clk, c_reg_write)
begin
   if Bus2IP_Clk'Event and Bus2IP_Clk='1' then
		c_reg_write_reg  <= c_reg_write;
		c_reg_write_reg1 <= c_reg_write_reg;
   end if;
end process register_c_reg_write;


  -- implement slave model software accessible register(s)
  SLAVE_REG_WRITE_PROC : process( Bus2IP_Clk ) is
  begin

    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
       user_RAM_WE_PLB <= '0'; -- default value for user_RAM_WE_PLB
 	    update_data_reg <= '0'; -- default value for update_data_reg;
		if Bus2IP_Reset = '1' then
		  user_write_RAM_reg <= (others => '0');
		  user_RAM_WE_PLB <='0';
        data_reg <= (others => '0');
        address_reg <= (others => '0');
        status_reg <= (others => '0');
        slv_reg3 <= (others => '0');
      else
        case slv_reg_write_sel is
          when "1000" =>
				user_RAM_WE_PLB <='1';
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                data_reg(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
				-- in all access modes, only 8 bits of the data from the OPB bus
            -- will be written into the user_data_regs register
            -- in this way, a specific register can be accessed with
            -- 32-bit access at USER_ADDR
            -- or 16-bit access at USER_ADDR or USER_ADDR+2
            -- or 8-bit access at USER_ADDR, USER_ADDR+1, USER_ADDR+2, or USER_ADDR+3
            -- 32-bit access at USER_ADDR, or 16-bit access at USER_ADDR+2, or 8-bit access at USER_ADDR+3
            if Bus2IP_BE="1111" or Bus2IP_BE="0011" or Bus2IP_BE="0001" then                 
               user_write_RAM_reg <= Bus2IP_Data(24 to 31);
            -- 16-bit access at USER_ADDR or 8-bit access at USER_ADDR+1
            elsif Bus2IP_BE="1100" or Bus2IP_BE = "0100" then 
               user_write_RAM_reg <= Bus2IP_Data(8 to 15);
            -- 8-bit access at USER_ADDR+2
            elsif Bus2IP_BE="0010" then
               user_write_RAM_reg <= Bus2IP_Data(16 to 23);
            -- 8-bit access at USER_ADDR
            elsif Bus2IP_BE="1000" then
               user_write_RAM_reg <= Bus2IP_Data(0 to 7);
            end if;
          when "0100" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                address_reg(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
				  update_data_reg <='1';
            end loop;
          when "0010" =>
            for byte_index in 0 to 2 loop -- only the upper 24 bits can be written from the PLB bus
              if ( Bus2IP_BE(byte_index) = '1' ) then
                status_reg(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0001" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg3(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when others => null;
          end case;
				if En_Read_Data_Bus ='1' then -- read the data from the EPP
					user_write_RAM_reg <= DB_I;
					--status_reg (1) <='1'; -- set the Write Performed bit
				end if;
            
            if Update_Addr_Reg = '1' then
               address_reg (0 to 23) <= (others => '0');
					address_reg (24 to 31) <= DB_I;
					status_reg  (24 to 31) <= DB_I;-- the last 8 bits of the status_reg contain the address of the register
															 -- set by the EPP interface, it cannot be changed by the processor
            end if;
            
               status_reg (0) <= Read_Requested;
               status_reg (1) <= Write_Performed;
               status_reg (2) <= EPP_Performing;
            	status_reg (8 to 11) <= STATE_DBG;
               
				-- set the last byte read in the data_reg
            -- and update the data_reg register when the value of the address register was changed
            if user_RAM_WE ='1' then
				   data_reg (0 to 23) <= (others => '0');
					data_reg (24 to 31) <= user_write_RAM_reg;
            elsif update_data_reg_del(1) = '1' then
				   data_reg (0 to 23) <= (others => '0');
					data_reg (24 to 31) <= user_read_RAM_reg;
				end if;
					-- update state machine status in the status register
				
       end if;
    end if;

  end process SLAVE_REG_WRITE_PROC;

	-- register update_data_reg
	register_update_data_reg: process (Bus2IP_Clk, update_data_reg, update_data_reg_del) is
	begin
		 if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
			update_data_reg_del(1 downto 0) <= update_data_reg_del(0) & update_data_reg;
		 end if;
	end process register_update_data_reg;
	
 -----------------------------------------------------
  -- RAM read and write process
  -----------------------------------------------------
  RAM_WRITE_READ: process (Bus2IP_Clk, user_write_RAM_reg, address_reg,
                      user_RAM_WE, user_RAM_WE_PLB, user_data_regs_RAM)
  begin
   if Bus2IP_Clk'event and Bus2IP_Clk='1' then
      if user_RAM_WE='1' or user_RAM_WE_PLB = '1' then
         user_data_regs_RAM(conv_integer(address_reg(24 to 31))) <= user_write_RAM_reg;
      end if;
        user_read_RAM_reg<=user_data_regs_RAM(conv_integer(address_reg(24 to 31)));
   end if;
  end process RAM_WRITE_READ;	

-- assign EPP output data 
  DB_O <= address_reg (24 to 31) when EN_ADDR_OUT = '1' else data_reg (24 to 31);

  -----------------------------------------------------
  -- register EPP output data and output enable
  -----------------------------------------------------   
-- reg_output_data: process(Bus2IP_Clk, NEXTSTATE, DB_O_CMB, address_reg)
-- begin
--    -- default values
--    if Bus2IP_Clk'event and Bus2IP_Clk='1' then
--      DB_T<='1';
--      DB_O<=DB_O_CMB;
--      -- send the address register contents when an address read is performed from the EPP bus
--      if NEXTSTATE=Send_Addr or NEXTSTATE=Wait_on_Astb_Read then
--         DB_O<= address_reg (24 to 31);
--      end if;
--      -- validate output data when sending address or data to the EPP bus
--      if NEXTSTATE=Send_ADDR or NEXTSTATE=Send_Data or NEXTSTATE=Wait_on_Astb_Read
--                             or NEXTSTATE=Wait_on_Dstb_Read then
--         DB_T<='0';
--      end if;
--    end if;
-- end process reg_output_data;
 
 -- assign the BUSY_CMB signal
-- BUSY_CMB <= '1' when NEXTSTATE = Wait_on_Astb_Write or
--                      NEXTSTATE = Wait_on_Astb_Read  or
--                      --NEXTSTATE = Wait_on_Isr_Write  or
--                      NEXTSTATE = Wait_on_Dstb_Read  or
--                      NEXTSTATE = Wait_on_Dstb_Write 
--              else '0';
                      
  -----------------------------------------------------
  -- register EPP BUSY signal
  -----------------------------------------------------   
--  register_BUSY_CMB: process(Bus2Ip_Clk, Bus2IP_Reset, BUSY_CMB)
--  begin
--   if Bus2IP_Clk'event and Bus2IP_Clk='1' then
--      if Bus2IP_Reset = '1' then BUSY<='0';
--      else BUSY<=BUSY_CMB; 
--      end if;
--   end if;
--  end process register_BUSY_CMB;
                      
--  EPP_Irpt <= '1' when STATE=Wait_on_Isr_Read or STATE=Wait_on_Isr_Write else '0';

  -- implement slave model software accessible register(s) read mux
  SLAVE_REG_READ_PROC : process( slv_reg_read_sel, data_reg, address_reg, status_reg, slv_reg3) is
  begin

    case slv_reg_read_sel is
      when "1000" => slv_ip2bus_data <= data_reg;
      when "0100" => slv_ip2bus_data <= address_reg;
      when "0010" => slv_ip2bus_data <= status_reg;
      when "0001" => slv_ip2bus_data <= slv_reg3;
      when others => slv_ip2bus_data <= (others => '0');
    end case;

  end process SLAVE_REG_READ_PROC;

  ------------------------------------------
  -- Example code to drive IP to Bus signals
  ------------------------------------------
  IP2Bus_Data  <= slv_ip2bus_data when slv_read_ack = '1' else
                  (others => '0');

  IP2Bus_WrAck <= slv_write_ack_reg1;
  IP2Bus_RdAck <= slv_read_ack;
  IP2Bus_Error <= '0';

  with STATE select
			STATE_DBG <= "0000" when Idle,                   -- Do nothing
							 "0001" when RnW_Addr,
                      "0010" when RnW_Data,
                      "0011" when Read_Addr,             -- Read the adress from the EPP
                      "0100" when Wait_on_Astb_Write,    -- wait until ASTB is reasserted in a write cycle
                      "0101" when Send_Addr,             -- Send the adress register content to the data bus
                      "0110" when Wait_on_Astb_Read,     -- wait until ASTB is reasserted in a read cycle
                      "0111" when Read_Data,             -- Read the data from the EPP
							 "1000" when Wait_on_Isr_Write,     -- Wait until the PLB bus is servicing the interrupt generated
                                                         -- by the EPP_USB interface on a write cycle 
							 "1001" when Wait_on_Dstb_Write,    -- wait until DSTB is reasserted in a write cycle
                      "1010" when Wait_on_Isr_Read,      -- Wait untill the PLB bus is servicing the interrupt generated
                                                         -- by the EPP_USB interface on a read cycle
                      "1011" when Send_Data,             -- Send the datas register content to the data bus
                      "1100" when Wait_on_Dstb_Read,     -- wait until DSTB is reasserted in a read cycle
                      "1111" when Done,                  -- State machine finish state
                      "1110" when others;


  -- unused EPP signal
  INT_USB <= '1';


end IMP;
