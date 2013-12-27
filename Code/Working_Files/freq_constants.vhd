--
-- This is a package which contains constant frequency information for 
--	the stepper motor unit. Mainly it contains the Q14.10 values 
--	for the frequencies
--

library ieee;
use ieee.std_logic_1164.all;


package freq_constants is
	
	-- Define the types
	type q_14_10_freq 	is std_logic_vector(23 downto 0);
	type q_14_10_freqs 	is array (0 to 5) of q_14_10_freq;

	-- Define the frequencies
	constant e2_082_407_hz 	: q_14_10_freq 	:= "000000010100100110100000";
	constant a2_110_000_hz	: q_14_10_freq	:= "000000011011100000000000";
	constant d3_146_832_hz	: q_14_10_freq	:= "000000100100101101010011";
	constant g3_195_998_hz	: q_14_10_freq	:= "000000110000111111111101";
	constant b3_246_942_hz	: q_14_10_freq	:= "000000111101101111000100";
	constant e4_329_628_hz	: q_14_10_freq	:= "000001010010011010000011";

	-- Define the array of frequencies
	constant expected_freqs : q_14_10_freqs :=	(
													e2_082_407_hz,
													a2_110_000_hz,
													d3_146_832_hz,
													g3_195_998_hz,
													b3_246_942_hz,
													e4_329_628_hz
												);


end package;
