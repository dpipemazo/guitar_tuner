----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:44:41 08/02/2010 
-- Design Name: 
-- Module Name:    signal_tester_core - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity signal_tester_core is
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

end signal_tester_core;

architecture Behavioral of signal_tester_core is

component frequency_meter is
port (
	clk 							: in std_logic;
	reset							: in std_logic;
	Reset_Frequency_Meter	: in std_logic;
	-- Unknown frequency input
   Fin							: in std_logic;
	-- signal asserted when frequency measurement has been done for 3-4 times
	done							: out std_logic;
	-- showing the frequency measurement data
	freq							: out std_logic_vector(31 downto 0);
	-- signal indicating frequency counter overflow
	overflow 					: out std_logic;
	-- division rate for the gate signal
	gate_div					   : in std_logic_vector( 31 downto 0);
	-- Compare value to generate variable duty cycle
	ctrl_async					: in std_logic
);

end component; 

type div_array is array (0 to C_NUM_OUTPUT_PAIRS - 1) of std_logic_vector (31 downto 0);

-- signal to be inverted at the output
signal data_o_signal			: std_logic_vector( C_NUM_OUTPUT_PAIRS - 1 downto 0);
-- signal generated and registered from the dividers
signal clkgen_signal_reg	: std_logic_vector( C_NUM_OUTPUT_PAIRS - 1 downto 0);
-- signal generated and registered from the dividers
signal clkgen_signal_cmb   : std_logic_vector( C_NUM_OUTPUT_PAIRS - 1 downto 0);

-- memory holding the array of division rates
signal divrate_mem 				: div_array;
-- memory holding the array of compare values
signal compare_value_mem 	: div_array;
-- memory holding the array of counters
signal counter_array 		: div_array;

signal clk_mux					: std_logic;

signal select_freq_m    	: std_logic;

begin


data_i <= CONN_SIGNALS_I;

frequency_meter_inst: frequency_meter
port map 
(
	clk								=> Bus2Ip_Clk,
	reset								=> Bus2Ip_Reset,
	Reset_Frequency_Meter		=> Reset_Frequency_Meter,					
	-- Unknown frequency input
   Fin				            =>	select_freq_m,
	-- signal asserted when frequency measurement has been done for 3-4 times
	done				            => done,
	-- showing the frequency measurement data
	freq				=> freq,
	-- signal indicating frequency counter overflow
	overflow 		=> overflow,
	-- division rate for the gate signal
	gate_div			=> gate_div,
	-- Compare value to generate variable duty cycle
	ctrl_async		=> ctrl_async
	-- signals connecting to the differential I/O busffers
);


--------------------------------------------------------------------------------------
-- MULTIPLEX CLOCK SIGNALS
--------------------------------------------------------------------------------------

BUFGMUX_inst : BUFGMUX
generic map (
CLK_SEL_TYPE => "SYNC" -- Synchronous or asynchronous clock switchover (SYNC or ASUNC)
)
port map (
O => clk_mux, -- 1-bit Clock MUX output
I0 => Bus2Ip_Clk, -- 1-bit Clock0 input
I1 => ext_clk, -- 1-bit Clock1 input
S => ext_int -- 1-bit Clock select input
);

--------------------------------------------------------------------------------------
-- INVERT CONN_SIGNALS_O
--------------------------------------------------------------------------------------
invert_output_signals: process (data_o_signal, invert) is
variable i: integer range 0 to (C_NUM_OUTPUT_PAIRS - 1);
begin
	for i in 0 to C_NUM_OUTPUT_PAIRS - 1 loop
		if invert(i) = '1' then
			CONN_SIGNALS_O(i) <= NOT data_o_signal (i);
		else
			CONN_SIGNALS_O(i) <= data_o_signal (i);
		end if;
	end loop;
end process invert_output_signals;

----------------------------------------------------------------------------------------
-- SELECT data_o_signal to be a logic level or a square wave signal
----------------------------------------------------------------------------------------
data_o_signal_ctrl : process (data_o, clkgen_signal_reg, signal_logic_square) is
variable i : integer range 0 to (C_NUM_OUTPUT_PAIRS - 1);
begin
	for i in 0 to C_NUM_OUTPUT_PAIRS - 1 loop
		if signal_logic_square(i) = '1' then
			data_o_signal(i) <= clkgen_signal_reg(i);
		else
			data_o_signal(i) <= data_o(i);
		end if;
	end loop;
end process data_o_signal_ctrl;


-------------------------------------------------------------------------------------------
-- write memory for the divrate val and compare_val
-------------------------------------------------------------------------------------------
write_divrate_mem: process ( Bus2Ip_Clk, Bus2Ip_Reset, divrate, mem_wen, address) is
begin
	if(Bus2Ip_Clk'event and Bus2Ip_Clk ='1') then
		if mem_wen = '1' then
			divrate_mem(conv_integer(address)) <= divrate;
		end if;
	end if;
end process write_divrate_mem;

write_compare_value_mem: process ( Bus2Ip_Clk, Bus2Ip_Reset, compare_value, mem_wen, address) is
begin
	if(Bus2Ip_Clk'event and Bus2Ip_Clk ='1') then
		if mem_wen = '1' then
			compare_value_mem(conv_integer(address)) <= compare_value;
		end if;
	end if;
end process write_compare_value_mem;


-------------------------------------------------------------------------------------------
-- FREQUENCY DIVIDERS
-------------------------------------------------------------------------------------------

FREQUENCY_DIVIDERS:
for i in 0 to (C_NUM_OUTPUT_PAIRS-1) generate
begin

clock_divider : process ( clk_mux,  Bus2Ip_Reset, divrate_mem(i), counter_array(i)) is
begin
	if (divrate_mem(i) = X"00000000") or (divrate_mem(i) = X"00000001") then
		counter_array(i) <= (others => '0');
	elsif(clk_mux'event and clk_mux ='1') then
		if((Bus2Ip_Reset='1') or (counter_array(i) = divrate_mem(i))) then
			counter_array(i) <= (others => '0');
		else
			counter_array(i)	<= counter_array(i) + X"00000001";
		end if;
	end if;
end process clock_divider;

clkgen_signal_cmb(i) <= '1' when (counter_array(i) < compare_value_mem(i)) else '0';

register_clkgen_signal: process (clk_mux, Bus2Ip_Reset, clkgen_signal_cmb(i)) is
begin
	if(clk_mux'event and clk_mux ='1') then
		if (Bus2Ip_Reset='1') then
			clkgen_signal_reg(i) <= '0';
		else
			clkgen_signal_reg(i) <= clkgen_signal_cmb(i);
		end if;
	end if;
end process register_clkgen_signal;

end generate;

multiplex_freq_to_meas: process (CONN_SIGNALS_I, fselect) is
variable i: integer range 0 to 31 :=0;
begin
	i := conv_integer(unsigned(fselect));

	if i > (C_NUM_INPUT_PAIRS-1) then
				select_freq_m <= CONN_SIGNALS_I(0);
	else
			select_freq_m <= CONN_SIGNALS_I(i);	
	end if;
end process multiplex_freq_to_meas;

end Behavioral;
