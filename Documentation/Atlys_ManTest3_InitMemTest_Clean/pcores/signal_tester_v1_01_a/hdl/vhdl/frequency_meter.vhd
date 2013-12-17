----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:16:12 08/02/2010 
-- Design Name: 
-- Module Name:    freq_m - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
-- use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity frequency_meter is
port (
	clk 							: in std_logic;
	reset							: in std_logic;
	Reset_Frequency_Meter	: in std_logic;
	-- Unknown frequency input
   Fin							: in std_logic;
	
	-- debug signals
	-- StC_dbg						: out std_logic_vector (4 downto 0);
	-- StN_dbg						: out std_logic_vector (4 downto 0);
	-- end of debug signals
	
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

end frequency_meter;

architecture Behavioral of frequency_meter is

constant Idle				: std_logic_vector (4 downto 0) := "00" & "100";
constant Counting			: std_logic_vector (4 downto 0) := "01" & "010";
constant Load				: std_logic_vector (4 downto 0) := "11" & "001";

signal StC, StN			: std_logic_vector (4 downto 0) := Idle;

attribute FSM_ENCODING : string;
attribute FSM_ENCODING of StC : signal is "USER";

signal Reset_Cnt      	: std_logic;
signal Enable_Cnt 	 	: std_logic;
signal Load_Frequency 	: std_logic;

--signal cnt_frequency		: integer;
signal cnt_frequency				: std_logic_vector (31 downto 0);
signal cnt_frequency_async		: std_logic_vector (31 downto 0);
signal cnt_frequency_async_n	: std_logic_vector (31 downto 0);

signal cnt_gate_div			: std_logic_vector (31 downto 0);
--signal cnt_gate_div 		: integer;
signal gate					: std_logic;

--to create a one-shot signal from Fin
signal Q_Fin				: std_logic_vector (1 downto 0);
signal Fin_one_shot		: std_logic;

-- to check for overflow condition 
signal overflow_cmb		: std_logic;

signal cnt_dones			: integer range 0 to 3 :=0;

begin

-- assign control signals for the frequency counter and data loading
Reset_Cnt			<= StC(2);
Enable_Cnt 	 		<= StC(1);
Load_Frequency 	<= StC(0);



-- register state process
reg_state: process (clk, reset, Reset_Frequency_Meter, StN)
begin
	if clk'EVENT and clk = '1' then
		if reset = '1' or Reset_Frequency_Meter = '1' then
			StC<= Idle;
		else
			StC <= StN;
		end if;
	end if;
end process reg_state;

-- transitions process
transitions: process (StC, gate)
begin
	StN <= StC;
	case StC is
	when Idle			=> if gate = '1' then StN <= Counting;
								end if;
	when Counting		=> if gate = '1' then StN <= Load;
								end if;
	when Load			=> StN <= Idle;
	when others 		=> StN <= Idle;
	end case;
end process transitions;

-- create one-shot signal from Fin
debounce_Fin : process (clk, Q_Fin, Reset_Frequency_Meter, reset, Fin)
begin
	if clk'event and clk='1' then
		if Reset_Frequency_Meter='1' or reset='1' then
			Q_Fin	<= "00";
		else
			Q_Fin <= Q_Fin(0) & Fin;
		end if;
	end if;
end process debounce_Fin;

Fin_one_shot <= Q_Fin (0) AND (NOT Q_Fin(1));

-- frequency measuring counter process
frequency_counter: process (clk, Reset_Cnt, Enable_Cnt, cnt_frequency, Fin_one_shot)
begin
	if clk'event and clk='1' then
		if Reset_Cnt='1' then
			cnt_frequency <= (others =>'0');
		elsif Enable_Cnt='1' AND Fin_one_shot = '1' then
			cnt_frequency <= cnt_frequency + X"00000001";		
		end if;
	end if;
end process frequency_counter;

overflow_cmb <='1' when cnt_frequency = X"FFFFFFFF" or cnt_frequency_async = X"FFFFFFFF" else '0';

assign_overflow : process (clk, cnt_frequency, overflow_cmb, reset)
begin
	if clk'event and clk='1' then
		if Reset_Frequency_Meter='1' or reset='1' then
			overflow <= '0';
		elsif overflow_cmb = '1' then
			overflow <= '1';
		end if;
	end if;
end process assign_overflow;

-- gate frequency divider process
gate_freq_divider : process (clk, gate_div, cnt_gate_div, Reset_Frequency_Meter, reset)
begin
	if clk'event and clk='1' then
		if Reset_Frequency_Meter='1' or reset='1' or (cnt_gate_div = (gate_div - X"00000001")) then
			cnt_gate_div <= (others => '0');
		else
			cnt_gate_div <= cnt_gate_div + X"00000001";
		end if;
	end if;
end process gate_freq_divider; 

gate <= '1' when cnt_gate_div = (gate_div - X"00000001") else '0';


-- load the frequency result at the end of counting
load_result : process (clk, reset, Reset_Frequency_Meter, Load_Frequency, cnt_frequency, ctrl_async)
begin
	if clk'event and clk='1' then
		if Reset_Frequency_Meter='1' or reset='1' then
			freq <= (others => '0');
		elsif Load_Frequency = '1' then
			if ctrl_async = '0' then
				freq <= cnt_frequency;
			else
				freq <= cnt_frequency_async;
			end if;
		end if;
	end if;
end process load_result;

count_dones: process (clk, Load_Frequency, cnt_dones)
begin
	if clk'event and clk='1' then
		if Reset_Frequency_Meter='1' or reset='1' then
			cnt_dones <= 0;
			done <='0';
		elsif Load_Frequency = '1' then
			cnt_dones <= cnt_dones + 1;
		end if;
	
		if cnt_dones = 3 then
			done <='1';
		end if;
	end if;
end process count_dones;

-- asynchronous frequency counter

cnt_frequency_async_n <= NOT cnt_frequency_async;

	FDCE_inst_0 : FDCE
	generic map (
	INIT => '0') -- Initial value of register ('0' or '1')
	port map (
	Q => cnt_frequency_async(0), -- Data output
	C => Fin, -- Clock input
	CE => Enable_Cnt, -- Clock enable input
	D => cnt_frequency_async_n(0), -- Data input
	CLR => Reset_Cnt -- Synchronous reset input
	);


ASYNC_COUNTER:
for i in 1 to 31 generate
begin

	FDCE_inst : FDCE
	generic map (
	INIT => '0') -- Initial value of register ('0' or '1')
	port map (
	Q => cnt_frequency_async(i), -- Data output
	C => cnt_frequency_async_n(i-1), -- Clock input
	CE => Enable_Cnt, -- Clock enable input
	D => cnt_frequency_async_n(i), -- Data input
	CLR => Reset_Cnt -- Synchronous reset input
	);

end generate;

-- Debug Signals
--	StC_dbg	<= Stc;
--	StN_dbg	<= StN;
-- End of debug signals



end Behavioral;

