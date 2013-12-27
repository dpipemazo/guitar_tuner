--
-- This is the file which controls the stepper motor.
--	and evaluates if the incoing frequency is indeed in
--	tune.
--	
--	This file will take the following inputs
--		1. Detected frequency : Q14.10
--		2. Current String
--		3. A signal to run the motor or not
--
--	This file will have the following outputs
--		1. Stepper motor step command
--		2. Tuned signal when frequency is within threshold
--

--
-- Libraries
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work;
use work.freq_constants.all;

entity TUNER is

	port(
		-- System clock
		clk				: in std_logic; -- system clock

		-- Signals from the UI unit
		run_motor		: in std_logic;	-- whether we should
									--	be running the motor or not
		-- The current string
		curr_string		: in std_logic_vector(2 downto 0); 	-- 000 = free tune, 
															-- 1 - 6 = EADGBE inthat order

		-- the frequency result
		div_quotient	: in std_logic_vector(13 downto 0);
		div_fractional	: in std_logic_vector(9 downto 0);

		-- Stepper motor commands
		step			: out std_logic;
		dir				: out std_logic;

		-- Whether or not the frequency is in tune
		tuned			: out std_logic

	);

end TUNER;


--
-- The architecture
--
architecture behavioral of TUNER is
	
	-- High and low thresholds for being in tune. These
	--	will be set to the expected frequency +/- 
	--	a certain number of cents' worth of error.
	signal high_threshold : std_logic_vector(23 downto 0);
	signal low_threshold  : std_logic_vector(23 downto 0);

	-- Signal for the expected frequency, since it's a 
	--	hassle to write all of the time
	signal expected_freq 	: std_logic_vector(23 downto 0);

	-- Put the input frequency together
	signal input_freq		: std_logic_vector(23 downto 0);

begin

	--
	-- Get the expected frequency based off of the current 
	--	string. The current string is 0 when in free
	--	tune mode. So account for that
	--
	expected_freq <= 	expected_freqs(to_integer(unsigned(curr_string) - 1)) when not std_match(curr_string, "000") else
						(others => '0');

	-- We need to figure out the thresholds. Initially, set the
	--	error to a bit under 5 cents by calculating the 
	--	expected frequency +/- the expected frequency/12. 
	high_threshold 	<= std_logic_vector(unsigned(expected_freq) + ("000000000" & unsigned(expected_freq(23 downto 9))));
	low_threshold 	<= std_logic_vector(unsigned(expected_freq) - ("000000000" & unsigned(expected_freq(23 downto 9))));

	--
	-- Attach the quotient to the fractional to get the input frequency
	--	in Q14.10 form
	--
	input_freq		<= div_quotient & div_fractional;










