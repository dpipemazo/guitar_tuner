------------------------------------------------------------------------------
-- user_logic.vhd - entity/architecture pair
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2010 Xilinx, Inc.  All rights reserved.            **
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
-- Version:           1.01.a
-- Description:       User logic.
-- Date:              Tue Aug 03 18:06:37 2010 (by Create and Import Peripheral Wizard)
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

entity user_logic is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    C_NUM_OUTPUT_PAIRS 				: integer		:= 2;
	 C_NUM_INPUT_PAIRS 				: integer		:= 2;
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_SLV_DWIDTH                   : integer              := 32;
    C_NUM_REG                      : integer              := 16
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
   -- ADD USER PORTS BELOW THIS LINE ------------------
    CONN_SIGNALS_I				: in  std_logic_vector( 0 to C_NUM_INPUT_PAIRS - 1);
	 CONN_SIGNALS_O				: out std_logic_vector( 0 to C_NUM_OUTPUT_PAIRS - 1);
	 SEL_HDMI_CONN					: out std_logic;
	 ext_clk						   : in std_logic;
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

end entity user_logic;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of user_logic is

  --USER signal declarations added here, as needed for user logic

  ------------------------------------------
  -- Signals for user logic slave model s/w accessible register example
  ------------------------------------------
  signal Data_O_REG                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal Data_I_REG                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal ADDRESS_REG                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal SIGNAL_LOGIC_SQUARE_REG          : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal EXT_INT_REG                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal INVERT_REG                       : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal DIVRATE_REG                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal FREQ_REG         		            : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal GATE_DIV_REG                     : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal COMPARE_VALUE_REG                : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal CTRL_REG           		         : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal STATUS_REG       	               : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg12                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg13                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg14                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg15                      : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_reg_write_sel              : std_logic_vector(0 to 15);
  signal slv_reg_read_sel               : std_logic_vector(0 to 15);
  signal slv_ip2bus_data                : std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal slv_read_ack                   : std_logic;
  signal slv_write_ack                  : std_logic;


  -- signal asserted when frequency measurement has been done for 3-4 times
  signal done									 : std_logic;
  -- signal indicating frequency counter overflow
  signal overflow 							 : std_logic;
	-- control signals for the frequency meter
  signal ctrl_async							 : std_logic;

  signal data_i						:  std_logic_vector(0 to C_SLV_DWIDTH-1);
  signal freq							:  std_logic_vector(0 to C_SLV_DWIDTH-1);
  
  -- pipe mem_wen
  signal mem_wen_pipe				: std_logic_vector (0 to 1);

component signal_tester_core is
generic 
(
	 C_NUM_OUTPUT_PAIRS 				: integer		:= 2;
	 C_NUM_INPUT_PAIRS 				: integer		:= 2
);
	
port
(
	Bus2Ip_Clk 					: in std_logic;
	Bus2Ip_Reset				: in std_logic;
	-- reset the frequency mater. This clears Done and the frequency meter internal counter
	Reset_Frequency_Meter				: in std_logic;
	-- Register data signals coming from the User Logic
	data_o						: in std_logic_vector( C_NUM_OUTPUT_PAIRS - 1 downto 0);
	data_i						: out std_logic_vector( C_NUM_INPUT_PAIRS - 1 downto 0);
	-- control signal that multiplexes between the system clock and an externally generated clock signal
	ext_int 						: in std_logic;
	-- external clock signal
	ext_clk						: in std_logic;
	-- control signal determininig whether the output port should come from the User logic register data (if the corresponding bit is logic 0)
	-- or from a clock signal (if logic 1)
	signal_logic_square		: in std_logic_vector( C_NUM_OUTPUT_PAIRS - 1 downto 0);
	-- invert the output signals
	invert 						: in std_logic_vector( C_NUM_OUTPUT_PAIRS - 1 downto 0);
	-- division rate for the gate signal
	gate_div					   : in std_logic_vector( 31 downto 0);
	-- showing the index of the input signal to be selected for frequency measurement
	fselect						: in std_logic_vector(4 downto 0);
	-- control signals for the frequency meter
	ctrl_async					: in std_logic;
	-- signal asserted when frequency measurement has been done for 3-4 times
	done							: out std_logic;
	-- showing the frequency measurement data
	freq							: out std_logic_vector(31 downto 0);
	-- signal indicating frequency counter overflow
	overflow 					: out std_logic;
	-- division rate to generate the internal clock
	divrate						: in std_logic_vector( 31 downto 0);
	-- Compare value to generate variable duty cycle
	compare_value  			: in std_logic_vector (31 downto 0);
	-- Address signal for multiple frequency outputs
	address						: in std_logic_vector (4 downto 0);
	-- Memory write enable signal
	mem_wen						: in std_logic;
	-- signals connecting to the differential I/O buffers
	CONN_SIGNALS_I				: in std_logic_vector ( C_NUM_INPUT_PAIRS - 1 downto 0);
	CONN_SIGNALS_O				: out std_logic_vector (C_NUM_OUTPUT_PAIRS - 1 downto 0));


end component;



begin

pipe_mem_wen: process (Bus2IP_Clk, Bus2IP_Reset, mem_wen_pipe, slv_reg_write_sel) is
begin
    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_Reset = '1' then
				mem_wen_pipe <= "00";
	   else
				mem_wen_pipe (0 to 1) <= mem_wen_pipe (1) & slv_reg_write_sel(2);
		end if;
	end if;
end process pipe_mem_wen;

SEL_HDMI_CONN <= CTRL_REG(C_SLV_DWIDTH - 9);

signal_tester_instance: signal_tester_core
generic map
(
		C_NUM_OUTPUT_PAIRS 				=> C_NUM_OUTPUT_PAIRS,
		C_NUM_INPUT_PAIRS 				=> C_NUM_INPUT_PAIRS
)
	
port map
(
	Bus2Ip_Clk 					=> Bus2Ip_Clk,
	Bus2Ip_Reset			 	=> Bus2Ip_Reset,
	-- reset the frequency mater. This clears Done and the frequency meter internal counter
	Reset_Frequency_Meter	=> CTRL_REG(C_SLV_DWIDTH - 7),
	-- Register data signals coming from the User Logic
	data_o						=> Data_O_REG(C_SLV_DWIDTH - C_NUM_OUTPUT_PAIRS to C_SLV_DWIDTH -1),
	data_i						=> data_i(C_SLV_DWIDTH - C_NUM_INPUT_PAIRS to C_SLV_DWIDTH -1),
	-- control signal that multiplexes between the system clock and an externally generated clock signal
	ext_int 						=> CTRL_REG(C_SLV_DWIDTH - 8),
	-- external clock signal
	ext_clk						=> ext_clk,
	-- control signal determininig whether the output port should come from the User logic register data (if the corresponding bit is logic 0)
	-- or from a clock signal (if logic 1)
	signal_logic_square		=> SIGNAL_LOGIC_SQUARE_REG(C_SLV_DWIDTH - C_NUM_OUTPUT_PAIRS to C_SLV_DWIDTH -1),
	-- invert the output signals
	invert 						=> INVERT_REG(C_SLV_DWIDTH - C_NUM_OUTPUT_PAIRS to C_SLV_DWIDTH -1),
	-- division rate for the gate signal
	gate_div					   => GATE_DIV_REG,
	-- showing the index of the input signal to be selected for frequency measurement
	fselect						=> CTRL_REG(C_SLV_DWIDTH - 5 to C_SLV_DWIDTH - 1),
	-- control signals for the frequency meter
	ctrl_async					=> CTRL_REG(C_SLV_DWIDTH - 6),
	-- signal asserted when frequency measurement has been done for 3-4 times
	done							=> done,
	-- showing the frequency measurement data
	freq							=> freq,
	-- signal indicating frequency counter overflow
	overflow 					=> overflow,
	-- division rate to generate the internal clock
	divrate						=> DIVRATE_REG,
	-- Compare value to generate variable duty cycle
	compare_value  			=> COMPARE_VALUE_REG,
	-- Address signal for multiple frequency outputs
	address						=> ADDRESS_REG (C_SLV_DWIDTH - 5 to C_SLV_DWIDTH - 1),
	-- Memory write enable signal
	mem_wen						=> mem_wen_pipe (0),
	-- signals connecting to the differential I/O busffers
	CONN_SIGNALS_I				=> CONN_SIGNALS_I,
	CONN_SIGNALS_O				=> CONN_SIGNALS_O
);



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
  ------------------------------------------
  slv_reg_write_sel <= Bus2IP_WrCE(0 to 15);
  slv_reg_read_sel  <= Bus2IP_RdCE(0 to 15);
  slv_write_ack     <= Bus2IP_WrCE(0) or Bus2IP_WrCE(1) or Bus2IP_WrCE(2) or Bus2IP_WrCE(3) or Bus2IP_WrCE(4) or Bus2IP_WrCE(5) or Bus2IP_WrCE(6) or Bus2IP_WrCE(7) or Bus2IP_WrCE(8) or Bus2IP_WrCE(9) or Bus2IP_WrCE(10) or Bus2IP_WrCE(11) or Bus2IP_WrCE(12) or Bus2IP_WrCE(13) or Bus2IP_WrCE(14) or Bus2IP_WrCE(15);
  slv_read_ack      <= Bus2IP_RdCE(0) or Bus2IP_RdCE(1) or Bus2IP_RdCE(2) or Bus2IP_RdCE(3) or Bus2IP_RdCE(4) or Bus2IP_RdCE(5) or Bus2IP_RdCE(6) or Bus2IP_RdCE(7) or Bus2IP_RdCE(8) or Bus2IP_RdCE(9) or Bus2IP_RdCE(10) or Bus2IP_RdCE(11) or Bus2IP_RdCE(12) or Bus2IP_RdCE(13) or Bus2IP_RdCE(14) or Bus2IP_RdCE(15);

  -- implement slave model software accessible register(s)
  SLAVE_REG_WRITE_PROC : process( Bus2IP_Clk ) is
  begin

    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_Reset = '1' then
        Data_O_REG <= (others => '0');
        Data_I_REG <= (others => '0');
        ADDRESS_REG <= (others => '0');
        SIGNAL_LOGIC_SQUARE_REG <= (others => '0');
        EXT_INT_REG <= (others => '0');
        INVERT_REG <= (others => '0');
        DIVRATE_REG <= (others => '0');
        FREQ_REG <= (others => '0');
        GATE_DIV_REG <= (others => '0');
        COMPARE_VALUE_REG <= (others => '0');
        CTRL_REG <= (others => '0');
        STATUS_REG <= (others => '0');
        slv_reg12 <= (others => '0');
        slv_reg13 <= (others => '0');
        slv_reg14 <= (others => '0');
        slv_reg15 <= (others => '0');
      else
        case slv_reg_write_sel is
          when "1000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                Data_O_REG(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0100000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                Data_I_REG(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0010000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                ADDRESS_REG(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0001000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                SIGNAL_LOGIC_SQUARE_REG(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000100000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                EXT_INT_REG(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000010000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                INVERT_REG(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000001000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                DIVRATE_REG(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000100000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                FREQ_REG(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000010000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                GATE_DIV_REG(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000001000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                COMPARE_VALUE_REG(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000100000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                CTRL_REG(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000010000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                STATUS_REG(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000001000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg12(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000000100" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg13(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000000010" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg14(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when "0000000000000001" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg15(byte_index*8 to byte_index*8+7) <= Bus2IP_Data(byte_index*8 to byte_index*8+7);
              end if;
            end loop;
          when others =>
				Data_I_REG <= data_i;
				FREQ_REG <= freq;
				STATUS_REG ( C_SLV_DWIDTH - 2) <= overflow;
				STATUS_REG(C_SLV_DWIDTH - 1) <= done;
        end case;
      end if;
    end if;

  end process SLAVE_REG_WRITE_PROC;

  -- implement slave model software accessible register(s) read mux
  SLAVE_REG_READ_PROC : process( slv_reg_read_sel, Data_O_REG, Data_I_REG, ADDRESS_REG, SIGNAL_LOGIC_SQUARE_REG, EXT_INT_REG, INVERT_REG, DIVRATE_REG, FREQ_REG, GATE_DIV_REG, COMPARE_VALUE_REG, CTRL_REG, STATUS_REG, slv_reg12, slv_reg13, slv_reg14, slv_reg15 ) is
  begin

    case slv_reg_read_sel is
      when "1000000000000000" => slv_ip2bus_data <= Data_O_REG;
      when "0100000000000000" => slv_ip2bus_data <= Data_I_REG;
      when "0010000000000000" => slv_ip2bus_data <= ADDRESS_REG;
      when "0001000000000000" => slv_ip2bus_data <= SIGNAL_LOGIC_SQUARE_REG;
      when "0000100000000000" => slv_ip2bus_data <= EXT_INT_REG;
      when "0000010000000000" => slv_ip2bus_data <= INVERT_REG;
      when "0000001000000000" => slv_ip2bus_data <= DIVRATE_REG;
      when "0000000100000000" => slv_ip2bus_data <= FREQ_REG;
      when "0000000010000000" => slv_ip2bus_data <= GATE_DIV_REG;
      when "0000000001000000" => slv_ip2bus_data <= COMPARE_VALUE_REG;
      when "0000000000100000" => slv_ip2bus_data <= CTRL_REG;
      when "0000000000010000" => slv_ip2bus_data <= STATUS_REG;
      when "0000000000001000" => slv_ip2bus_data <= slv_reg12;
      when "0000000000000100" => slv_ip2bus_data <= slv_reg13;
      when "0000000000000010" => slv_ip2bus_data <= slv_reg14;
      when "0000000000000001" => slv_ip2bus_data <= slv_reg15;
      when others => slv_ip2bus_data <= (others => '0');
    end case;

  end process SLAVE_REG_READ_PROC;

  ------------------------------------------
  -- Example code to drive IP to Bus signals
  ------------------------------------------
  IP2Bus_Data  <= slv_ip2bus_data when slv_read_ack = '1' else
                  (others => '0');

  IP2Bus_WrAck <= slv_write_ack;
  IP2Bus_RdAck <= slv_read_ack;
  IP2Bus_Error <= '0';

end IMP;
