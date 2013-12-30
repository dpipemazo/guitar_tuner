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

	-- Define the dividers. When we are in this mode, we are trying to 
	--	get the frequency into a bin around 600. This will allow us to 
	--	detect a little bit less than the frequency/2. This intentional, 
	--	since we do not want to pick up the signature of 
	--	the frequency/2 and incorrectly diagnose that frequency
	--
	-- The formula for calculating the divider is: 
	-- 
	--		div = 10^8/(freq*600)
	--
	-- However, 600 is mildly arbitrary. You want the divider to be as close
	--	to an integer as possible, so move the bin (600) up to achieve this.
	--	but make sure the bin is somewhere between 600 and 650, preferably closer to 600. 
	constant e2_divider : std_logic_vector(11 downto 0) := "011111000010"; -- Divider: 1986,  Bin : 611
	constant a2_divider : std_logic_vector(11 downto 0) := "010111001011"; -- Divider: 1483,  Bin : 613
	constant d3_divider : std_logic_vector(11 downto 0) := "010001100010"; -- Divider: 1122,  Bin : 607
	constant g3_divider : std_logic_vector(11 downto 0) := "001101000011"; -- Divider: 835,   Bin : 611
	constant b3_divider : std_logic_vector(11 downto 0) := "001010011010"; -- Divider: 666,   Bin : 608
	constant e4_divider : std_logic_vector(11 downto 0) := "000111110011"; -- Divider: 499,   Bin : 608

	-- Define the array of dividers
	constant string_dividers : string_divider := 	(
														e2_divider,
														a2_divider,
														d3_divider,
														g3_divider,
														b3_divider,
														e4_divider
													);

	-- Now make an array of the bins which are a result of being in tune
	type string_bin is array(0 to 5) of std_logic_vector(10 downto 0);

	-- The bin here matches the bin in the comments above
	constant e2_bin : std_logic_vector(10 downto 0) := "01001100011";	-- Divider: 1986,  Bin : 611
	constant a2_bin : std_logic_vector(10 downto 0) := "01001100101";	-- Divider: 1483,  Bin : 613
	constant d3_bin : std_logic_vector(10 downto 0) := "01001011111";	-- Divider: 1122,  Bin : 607
	constant g3_bin : std_logic_vector(10 downto 0) := "01001100011";	-- Divider: 835,   Bin : 611
	constant b3_bin : std_logic_vector(10 downto 0) := "01001100000";	-- Divider: 666,   Bin : 608
	constant e4_bin : std_logic_vector(10 downto 0) := "01001100000";	-- Divider: 499,   Bin : 608

	-- Define the array of bins
	constant string_bins : string_bin := 	(
												e2_bin,
												a2_bin,
												d3_bin,
												g3_bin,
												b3_bin,
												e4_bin
											);


end package;
