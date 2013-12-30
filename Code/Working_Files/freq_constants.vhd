--
-- This is a package which contains constant frequency information for 
--	the stepper motor unit. Mainly it contains the Q14.10 values 
--	for the frequencies
--

library ieee;
use ieee.std_logic_1164.all;


package freq_constants is
	
	-- Define the types
	type q_14_10_freqs 	is array(0 to 5) of std_logic_vector(23 downto 0);

	-- Define the frequencies
	constant e2_082_407_hz 	: std_logic_vector(23 downto 0) := "000000010100100110100000";	-- 82.407 
	constant a2_110_000_hz	: std_logic_vector(23 downto 0)	:= "000000011011100000000000";	-- 110.000
	constant d3_146_832_hz	: std_logic_vector(23 downto 0)	:= "000000100100101101010011";	-- 146.832
	constant g3_195_998_hz	: std_logic_vector(23 downto 0)	:= "000000110000111111111101";	-- 195.998
	constant b3_246_942_hz	: std_logic_vector(23 downto 0)	:= "000000111101101111000100";	-- 246.942
	constant e4_329_628_hz	: std_logic_vector(23 downto 0)	:= "000001010010011010000011";	-- 329.628

	-- Define the array of frequencies
	constant expected_freqs : q_14_10_freqs :=	(
													e2_082_407_hz,
													a2_110_000_hz,
													d3_146_832_hz,
													g3_195_998_hz,
													b3_246_942_hz,
													e4_329_628_hz
												);

	-- Define the array of sampling dividers to use
	type string_divider is array(0 to 5) of std_logic_vector(11 downto 0);

	-- Define the dividers
	constant e2_divider : std_logic_vector(23 downto 0) := "010010100001"; -- 1185
	constant a2_divider : std_logic_vector(23 downto 0) := "001101111000"; -- 888
	constant d3_divider : std_logic_vector(23 downto 0) := "001010011001"; -- 665
	constant g3_divider : std_logic_vector(23 downto 0) := "000111110010"; -- 498
	constant b3_divider : std_logic_vector(23 downto 0) := "000110001100"; -- 396
	constant e4_divider : std_logic_vector(23 downto 0) := "000100101000"; -- 296

	-- Define the array of dividers
	constant string_dividers : string_divider := 	(
														e2_divider,
														a2_divider,
														d3_divider,
														g3_divider,
														b3_divider,
														e4_divider
													);



end package;
