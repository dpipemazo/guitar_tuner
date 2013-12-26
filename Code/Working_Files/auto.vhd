--
-- 	This is the VHDL file for the entire autocorrelation unit. 
--	
--	Description:
--		This file contains two entities, the low-level single-
--		sample autocorrelation block and the amalgamated high-
--		level block. The high-level block is made up of 
--		256 low-level blocks connected in series.
--
--		The high-level autocorrelation block will take
--		the following inputs:
--			1. clock -- A clock which runs at the same frequency
--						as the sample clock. This clock should only
--						go high when a new sample is available
--			2. sample -- A 2-bit sample value. A new sample 
--						should be available for each clock
--			3. go 	 -- An active high signal which should be 
--					 	asserted for at least one sample clock
--						and will begin an autocorrelation process.
--
--		The high-level autocorrelation block will have the 
--		following outputs:
--			1. max_idx -- The index of the sample with the 
--							highest autocorrelation value. 
--							This can then be converted to 
--							a detected frequency be dividing 
--							the sampling frequency by this value. 
--			2. done 	-- an active high sample that indicates
--							that sampling/autocorrelation is 
--							complete. 
--
--	Operation:
--
--		The high-level autocorrelation unit will consist of 
--		256 single-sample blocks connected in series. Each single-
--		sample block will take the following inputs:
--			1. clock -- same as high-level
--			2. sample_in -- a 2-bit sample with new data. 
--		Each single-sample block has the following outputs:
--			1. sample_out -- a 2-bit sample with current data
--			2. data_out --	a single bit which is the result of 
--							the autocorrelation between the 
--							two samples within the unit.
--		Each single-sample block stores two samples. For the 
--		first 256 samples, bot samples are the same. The sample_in
--		input is latched into both sample registers which then
--		feed into the sample_out output. Accordingly, after
--		256 clocks, the conencted unit contains samples 1-256
--		and is ready to find the autocorrelation of index 0. For
--		samples 257-512, the sample_in is used to feed into one 
--		of the latches, but not the other. In this manner, 
--		a sliding window of 256 samples autocorrelated
--		against the first 256 samples is achieved, and can
--		be used to compute autocorrelations of indices 0 to 255. 
--
--		On each clock, each small block will output a 1 or 0, based
--		on whether or not the two samples in its registers match. 
--		These outputs are then counted using a series of adders
--		to determine how many 1s each autocorrelation index has. 
--		The number of 1s is then compared to the known maximum, 
--		and if it is greater, becomes the new maximum. 
--
--		In order to connect this unit to a sample source:
--			Simply connect the sample source to the "sample"
--			input on the high-level unit, and feed the sample
--			clock to this unit. 
--
--	Assumptions:
--		On each clock, the outputs of the single-block units must
--		be run through 8 series of adders, and then a comparator.
--		The clock must be slow enough to allow for this to happen. 
--		The clock must also be slow enough to allow the op signal 
--		to pass through all 256 blocks before the next clock. The
--		minimum clock frequency which we need is 50KHz, since we 
--		need to sample at 128*f_interest, and the largest
--		f_interest is ~350Hz, though being able to identify higher 
--		frequencies would be nice. 
--
--	Revision History:
--		Dan Pipe-Mazo 12/18/14 	Initial Revision
--


--
-- Libraries
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

--
--
---
----
----- SINGLE AUTOCORRELATION BLOCK CODE
----
---
--
--

--
-- Declare the I/O
--
entity SINGLE_AUTO is
	
	port(
		-- Inputs
		clock		: in std_logic;						-- sample clock
		sample_in 	: in std_logic_vector(1 downto 0);	-- new sample data
		op_in	 	: in std_logic;						-- If low, then 
														--	put sample_in into
														--	both registers, else
														--	only register 2
		-- Outputs
		sample_out  : out std_logic_vector(1 downto 0); -- current sample data
		auto_out	: out std_logic;					-- Autocorrelation result
		op_out		: out std_logic						-- Same as op_in. Pass
														--	directly through, do 
														--	not latch.
	);

end SINGLE_AUTO;

--
-- This is architecture for the single autocorrelation block. For the 
--	first 256 clocks, the sample_in should be copied into both register 1
--	and register 2. 
--
--	For the second 256 clocks, the sample_in should only be copied into 
--	register 2. 
--	
--  sample_out should always simply be the output of register 2. 
--
--  auto_out should be 1 if register 1 == register 2, else 0. 
--
architecture behavioral of SINGLE_AUTO is
	
	-- The two internal registers, need to be DFF'd
	signal register_1 : std_logic_vector(1 downto 0);
	signal register_2 : std_logic_vector(1 downto 0);

	-- Mux result for register 1
	signal reg_1_mux : std_logic_vector(1 downto 0);

begin

	-- Pass the operation bit through
	op_out 		<= op_in;

	-- Mux the inputs to the internal registers
	reg_1_mux 	<= 	sample_in when (op_in = '0') else
					register_1;

	-- Calculate the output. Output a "1" if the two registers
	--	match, else a 0.
	auto_out 	<=  '1' when (std_match(register_1, register_2)) else
					'0';

	-- Always output register 2 as the sample output
	sample_out <= register_2;

	-- Finally, DFF the registers on the rising edge of the clock
	doDFF	: process(clock)
	begin

		-- DFF all of the registers based on the clock. 
		if (rising_edge(clock)) then
			-- Put the appropriate value in register 1 based on the mux
			register_1 <= reg_1_mux;
			-- Always put the input sample in register 2
			register_2 <= sample_in;
		end if;
	end process;

end architecture;


--
--
---
----
----- COMPLETE AUTOCORRELATION BLOCK CODE
----
---
--
--

--
-- Libraries
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all; 

--
-- Declare the I/O
--
entity AUTOCORRELATE is 
	
	port (
		-- Inputs
		clock 		: in std_logic;						-- the system clock, 100MHz. 

		sample  	: in std_logic_vector(1 downto 0);	-- sample input

		n_reset   	: in std_logic;						-- active low reset

		-- Outputs
		result_div  : out std_logic_vector(11 downto 0);-- Divider used which gets
														-- close to 1024xf_interest	

		result_idx	: out std_logic_vector(10 downto 0);-- Index of the sample
														-- which had the maximum
														-- autocorrelation value. Should
														-- be close to 1024.

		done		: out std_logic						-- Sampling is complete and the 
														--	frequency has been found
	);

end AUTOCORRELATE;

--
-- This is the architecture to the entire autocorrelation block. 
--
-- The architecture needs to assemble 1088 of the SINGLE_AUTO blocks
--	and connect their I/O in series. The sample input of this block
--	will be fed into the final SINGLE_AUTO block in the array. 
--
-- We need 1100 sample blocks in order to facilitate our algorithm. 
--	The algorithm attempts to sample at 1024 times the audio 
--	frequency. It begins by sampling at the lowest frequency 
--	possible, and keeps increasing frequency until the correct sampling
--	frequency is found. Every sampling round, the divider for
--	the sampling clock to divide down the system clock is scaled
--	by result/1024. The reason 1024 is useful is because it eliminates the 
--	need for a divider. 1088 units are being used because the algorithm
--	will converge for >= 1076 units theoretically, so an extra 12 units
--	to get to a power of 2 seemed like a good idea. Also, powers 
--	of 2 are single bits, so it only adds one more bit to the done-check.
--
--	The system will be done with a round of sampling when bits 11 and 6 are set. 
--
-- This block will take the "go" signal as an indication to begin sampling, 
--	and then will assert the "done" signal when done sampling.
--
architecture behavioral of AUTOCORRELATE is 
	
	-- Counter for the system. Measures out the 2048 sample clock
	--	cycle which the system runs on. Range 0 - 2047
	signal samp_counter 	: std_logic_vector(11 downto 0);
	-- Mux result for the counter
	signal samp_counter_mux : std_logic_vector(11 downto 0); 
	-- Signal if the sample counter is at a maximum
	signal cycle_done : std_logic;

	-- Declare our sample clock as a clock
	signal sample_clock : std_logic;
	signal sample_clock_mux : std_logic;
	-- Declare the buffer_type itself
   	attribute buffer_type : string;
	attribute buffer_type of sample_clock : signal is "BUFG";

	-- Signals for figuring out the clock divider
	signal clk_div_x_idx  	: std_logic_vector(22 downto 0);
	signal clk_div			: std_logic_vector(11 downto 0);
	signal clk_div_mux 		: std_logic_vector(11 downto 0);
	signal new_clk_div		: std_logic_vector(11 downto 0);

	-- Counter for our sample clock. Needs to be same bitwidth as 
	--	the divider
	signal clk_counter 		: std_logic_vector(11 downto 0);
	signal clk_counter_mux 	: std_logic_vector(11 downto 0);
	signal clk_counter_inc  : std_logic_vector(11 downto 0);

	-- Signals to link together the autocorrelation units
	type sample_array 	is array(1088 downto 0) of std_logic_vector(1 downto 0);
	signal samples 		: sample_array;
	signal ops 			: std_logic_vector(1088 downto 0);
	signal autos 		: std_logic_vector(1087 downto 0);

	-- Signals to do the hamming weight addition for the first 1024
	type hamming_1_1024 is array(511 downto 0) 	of std_logic_vector(1 downto 0);
	type hamming_2_1024 is array(255 downto 0) 	of std_logic_vector(2 downto 0);
	type hamming_3_1024 is array(127 downto 0)	of std_logic_vector(3 downto 0);
	type hamming_4_1024 is array(63  downto 0)	of std_logic_vector(4 downto 0);
	type hamming_5_1024 is array(31  downto 0)	of std_logic_vector(5 downto 0);
	type hamming_6_1024 is array(15  downto 0)	of std_logic_vector(6 downto 0);
	type hamming_7_1024 is array(7   downto 0)	of std_logic_vector(7 downto 0);
	type hamming_8_1024 is array(3   downto 0)	of std_logic_vector(8 downto 0);
	type hamming_9_1024 is array(1   downto 0)	of std_logic_vector(9 downto 0);

	signal hamming_1s_1024 		: hamming_1_1024;
	signal hamming_2s_1024 		: hamming_2_1024;
	signal hamming_3s_1024 		: hamming_3_1024;
	signal hamming_4s_1024 		: hamming_4_1024;
	signal hamming_5s_1024 		: hamming_5_1024;
	signal hamming_6s_1024 		: hamming_6_1024;
	signal hamming_7s_1024 		: hamming_7_1024;
	signal hamming_8s_1024 		: hamming_8_1024;
	signal hamming_9s_1024 		: hamming_9_1024;
	signal final_hamming_1024 	: std_logic_vector(10 downto 0);

	-- Signals to do the hamming weight addition for the final 64
	type hamming_1_64 is array(31 downto 0) 	of std_logic_vector(1 downto 0);
	type hamming_2_64 is array(15 downto 0) 	of std_logic_vector(2 downto 0);
	type hamming_3_64 is array(7  downto 0)		of std_logic_vector(3 downto 0);
	type hamming_4_64 is array(3  downto 0)		of std_logic_vector(4 downto 0);
	type hamming_5_64 is array(1  downto 0)		of std_logic_vector(5 downto 0);

	signal hamming_1s_64 		: hamming_1_64;
	signal hamming_2s_64 		: hamming_2_64;
	signal hamming_3s_64 		: hamming_3_64;
	signal hamming_4s_64 		: hamming_4_64;
	signal hamming_5s_64 		: hamming_5_64;
	signal final_hamming_64	  	: std_logic_vector(6 downto 0);

	-- Sum at the end of the hamming weight chain
	signal final_hamming	  : std_logic_vector(10 downto 0);

	-- Index at which maximum occurred. Needs to be same bitwidth as max_idx
	signal max_idx_mux 		: std_logic_vector(10 downto 0);
	signal max_idx_val		: std_logic_vector(10 downto 0);
	signal max_idx_result 	: std_logic_vector(11 downto 0);
	-- Maximum autocorrelation value. Needs to be same bitwidth as final_hamming
	signal max_auto_mux		: std_logic_vector(10 downto 0);
	signal max_auto_val 	: std_logic_vector(10 downto 0);
	-- Signals for seeing if it is a valid cycle to store results or if we have a new maximum	
	signal new_max			: std_logic;
	signal valid_auto		: std_logic;
	signal second_half		: std_logic;
	signal done_sig			: std_logic;
	signal had_max			: std_logic;
	signal cycle_done_mux 	: std_logic;
	signal max_idx_one		: std_logic;

	-- The SINGLE_AUTO component
	component SINGLE_AUTO
		port(
			-- Inputs
			clock		: in std_logic;						-- sample clock
			sample_in 	: in std_logic_vector(1 downto 0);	-- new sample data
			op_in	 	: in std_logic;						-- If low, then 
															--	put sample_in into
															--	both registers, else
															--	only register 2
			-- Outputs
			sample_out  : out std_logic_vector(1 downto 0); -- current sample data
			auto_out	: out std_logic;					-- Autocorrelation result
			op_out		: out std_logic						-- Same as op_in. Pass
															--	directly through, do 
															--	not latch.
		);
	end component;

begin

	--
	---
	---- SAMPLE CLOCK AND ASSOCIATED LOGIC
	---
	--

	--
	-- The clock divider result. The new clock divider is equal to:
    --                          (clk_div * max_idx_val)
    --                          ------------------------
    --                                  1024
    -- Since we want to scale the divider so that our frequency winds up in the 
    --	1024th bin. We also need to round this result in order for the 
    --	algorithm to work. 
    --
    -- In order to perform this calculation, we are going to multiply
    --	clk_div by max_idx_val and then shift the result right by 10.
    --	We will add 1 to the result if bit 9 of the multiply result was set
    --	in order to round it. 
    clk_div_x_idx 	<= 	std_logic_vector(unsigned(clk_div) * unsigned(max_idx_val));

    -- Perform the divide by 1024 with rounding
    new_clk_div 	<= 	clk_div_x_idx(21 downto 10) when (clk_div_x_idx(9) = '0') else
    					std_logic_vector(unsigned(clk_div_x_idx(21 downto 10)) + 1);

    -- Do the multiplexing for the clock divider. When reset is high, set the divider 
    --	to the maximum. If reset is not high and we are sampling, keep the divider, 
    --	otherwise if we are done, then use the new divider. 
    -- Need to error-check. If we picked up an overtone, then our maximum value 
    --	will be 1. In this instance, since we think we picked up an overtone, 
    --	multiply the divider by 2. 
    clk_div_mux 	<= 	(others => '1') 				when (n_reset = '0') or (done_sig = '1') else
    					new_clk_div						when ( (cycle_done = '1') and (max_idx_one = '0') ) else
    					(clk_div(10 downto 0) & "0")	when ( (cycle_done = '1') and (max_idx_one = '1') ) else
    					clk_div;

    --
    -- Signal saying that the max index is not one, we need this for 
    --	error-checking
    --
    max_idx_one <=  '1' when std_match(max_idx_val, std_logic_vector(to_unsigned(1, max_idx_val'length))) else
    				'0'; 

	--
	-- Logic for which sample we are currently taking. The sample counter
	--	will reset to 0 after reset is asserted and will stick at the 
	--	maximum value until reset is asserted, else, increment. 
	--
	samp_counter_mux <= (others => '0') when ((cycle_done = '1') or (n_reset = '0')) else
						std_logic_vector(unsigned(samp_counter) + 1);

	-- We are done with a cycle when the cycle counter has reached its maximum
	--	or once we find a maximum autocorrelation value which is not the 
	--	first index. 
	cycle_done_mux 	<= '1' when ( (samp_counter(11) = '1') and (samp_counter(7) = '1') and (cycle_done = '0') ) or
						   ( (new_max = '0') and (had_max = '1') and (max_idx_one = '0') ) else
					   '0';

	-- We are completely done when the old divider is equal to the new divider or
	--	the index found is >= 1024 at the end of any given cycle. The second
	--	clause provides termination when the frequency is in-between dividers and oscillates.
	--	This prevents the divider from ever increasing, but the array was calculated 
	--	to have a length such that it should never have to. Also, there
	--	is higher accuracy in indieces in the array past 1024, so that's
	--	all we really care about. This won't work if the current strategy
	--	of cycling up from the lowest frequency is abandoned. 
	done_sig 		<= 	'1' when ( (std_match(new_clk_div, clk_div) or 
								   (std_match(max_idx_val, std_logic_vector(to_unsigned(1025, max_idx_val'length))))
								   ) and (cycle_done = '1') ) else
						'0';
	-- Put the done signal on the line a clock after. 
	done 			<= done_sig;


	--
	-- Logic for generating the sample clock. The sample clock will always be 
	--	running, and will wrap around the divider value. It will be an approximately
	--	50% duty cycle clock.
	--

	-- Incrementor
	clk_counter_inc <= std_logic_vector(unsigned(clk_counter) + 1);
	-- Need to wrap the sample clock 
	clk_counter_mux <= 	clk_counter_inc when (unsigned(clk_counter_inc) <  unsigned(clk_div)) else
						(others => '0');
	-- Sample clock is high when count is greater than divisor/2, else low
	sample_clock_mux <= '1' when ((unsigned(clk_counter) < ("0" & unsigned(clk_div(11 downto 1)))) or (n_reset = '0')) else
						'0';

	--
	---
	---- AUTOCORRELATION LOGIC
	---
	--

	-- Connect the inputs to the main unit to the autocorrelation
	--	units. Make the input samples to the main unit the input samples
	--	to the array of units. 
	samples(0) 	<= sample;

	-- We are in the second half of the autocorrelation when we are between 1088 and 2176
	second_half <= 	'1' when (	((samp_counter(10) and (samp_counter(9) or samp_counter(8) or samp_counter(7) or samp_counter(6))) = '1') 	or
				  				((samp_counter(11) and (not samp_counter(7))) = '1') 														or
				  				std_match(samp_counter, std_logic_vector(to_unsigned(2176, samp_counter'length))) ) 						else
					'0';

	-- The operation can be the same as the valid_auto bit, since we want to do the second
	--	type of operation for the second half of the sampling
	ops(0) 		<= second_half;

	-- First, string together autocorrelation units
	genautos: for i in 0 to 1087 generate 
	begin

		autox: SINGLE_AUTO
			port map(

				-- Input
				clock 		=> sample_clock,
				sample_in 	=> samples(i),
				op_in 		=> ops(i),

				-- Output
				sample_out 	=> samples(i + 1),
				op_out		=> ops(i + 1),
				auto_out 	=> autos(i)

			);

	end generate genautos;

	-- NOTE: sample_array(512) and ops(512) will not be connected to anything.
	--	They don't matter, since once a sample gets shifted out, we are done with
	--	it and the operation is just a feedthrough.

	--  Now, we need to put together
	--	the hamming weight adder for the autos. Do this with a bunch of 
	--	for-generate adders.
	genham1s: for i in 0 to 511 generate
	begin
		-- Couldn't figure out how to to a single add of bits, so just do it myself without the 
		--	need for an adder. 
		hamming_1s_1024(i)(0) <= autos(2*i) xor autos(2*i + 1);
		hamming_1s_1024(i)(1) <= autos(2*i) and autos(2*i + 1);
	end generate genham1s;

	genham2s: for i in 0 to 255 generate
	begin
		hamming_2s_1024(i) <= std_logic_vector(("0" & unsigned(hamming_1s_1024(2*i))) + ("0" & unsigned(hamming_1s_1024(2*i + 1))));
	end generate genham2s;

	genham3s: for i in 0 to 127 generate
	begin
		hamming_3s_1024(i) <= std_logic_vector(("0" & unsigned(hamming_2s_1024(2*i))) + ("0" & unsigned(hamming_2s_1024(2*i + 1))));
	end generate genham3s;

	genham4s: for i in 0 to 63 generate
	begin
		hamming_4s_1024(i) <= std_logic_vector(("0" & unsigned(hamming_3s_1024(2*i))) + ("0" & unsigned(hamming_3s_1024(2*i + 1))));

	end generate genham4s;

	genham5s: for i in 0 to 31 generate
	begin
		hamming_5s_1024(i) <= std_logic_vector(("0" & unsigned(hamming_4s_1024(2*i))) + ("0" & unsigned(hamming_4s_1024(2*i + 1))));

		-- Bring in the final 64 at this level 
		hamming_1s_64(i)(0) <= autos(2*i + 1024) xor autos(2*i + 1025);
		hamming_1s_64(i)(1) <= autos(2*i + 1024) and autos(2*i + 1025);
	end generate genham5s;

	genham6s: for i in 0 to 15 generate
	begin
		hamming_6s_1024(i) 	<= std_logic_vector(("0" & unsigned(hamming_5s_1024(2*i))) + ("0" & unsigned(hamming_5s_1024(2*i + 1))));

		hamming_2s_64(i) 	<= std_logic_vector(("0" & unsigned(hamming_1s_64(2*i))) + ("0" & unsigned(hamming_1s_64(2*i + 1))));
	end generate genham6s;

	genham7s: for i in 0 to 7 generate
	begin
		hamming_7s_1024(i) 	<= std_logic_vector(("0" & unsigned(hamming_6s_1024(2*i))) + ("0" & unsigned(hamming_6s_1024(2*i + 1))));

		hamming_3s_64(i) 	<= std_logic_vector(("0" & unsigned(hamming_2s_64(2*i))) + ("0" & unsigned(hamming_2s_64(2*i + 1))));
	end generate genham7s;

	genham8s: for i in 0 to 3 generate
	begin
		hamming_8s_1024(i) 	<= std_logic_vector(("0" & unsigned(hamming_7s_1024(2*i))) + ("0" & unsigned(hamming_7s_1024(2*i + 1))));

		hamming_4s_64(i) 	<= std_logic_vector(("0" & unsigned(hamming_3s_64(2*i))) + ("0" & unsigned(hamming_3s_64(2*i + 1))));
	end generate genham8s;

	genham9s: for i in 0 to 1 generate
	begin
		hamming_9s_1024(i) 	<= std_logic_vector(("0" & unsigned(hamming_8s_1024(2*i))) + ("0" & unsigned(hamming_8s_1024(2*i + 1))));

		hamming_5s_64(i) 	<= std_logic_vector(("0" & unsigned(hamming_4s_64(2*i))) + ("0" & unsigned(hamming_4s_64(2*i + 1))));
	end generate genham9s;

	-- Put together the final hamming value
	final_hamming_1024 	<= std_logic_vector(("0" & unsigned(hamming_9s_1024(0))) + ("0" & unsigned(hamming_9s_1024(1))));
	final_hamming_64 	<= std_logic_vector(("0" & unsigned(hamming_5s_64(0))) + ("0" & unsigned(hamming_5s_64(1))));
	-- Do not need to worry about overflow out of 11 bits, since 11 bits can hold 2048 max and out max is 1088
	final_hamming 		<= std_logic_vector(unsigned(final_hamming_1024) + ("0000" & unsigned(final_hamming_64)));

	--
	---
	---- MAXIMUM ITERATION LOGIC
	---
	--

	--
	-- We are looking for the final maximum in the first string of maximums
	--	which exceeds the autocorrelation value at the first index.
	--	
	-- We cannot simply look for the first maximum, it must be the final one,
	--	since otherwise we sacrifice accuracy
	--

	-- We have valid autocorrelate values from 1089 to 2176. 
	valid_auto <= 	'1' when (second_half = '1') and not std_match(samp_counter, std_logic_vector(to_unsigned(1088, samp_counter'length))) else
					'0';	  


	-- We have had a valid new maximum autocorrelation value
	new_max <= 	'1' when ((unsigned(final_hamming) > unsigned(max_auto_val)) and (valid_auto = '1') and (cycle_done = '0')) else
				'0';

	-- Want max_auto to be 0 when not in the final 256 clocks, 
	max_auto_mux <= final_hamming 	when (new_max = '1') else
					max_auto_val	when ((valid_auto = '1') or (cycle_done = '1')) else
					(others => '0');

	-- Need to subtract 1088 from the sample counter to get the current sample's index.
	max_idx_result <= std_logic_vector(unsigned(samp_counter) - to_unsigned(1088, samp_counter'length));

	-- Want to use the new index if we have a new max, keep the value if we don't have a new max, 
	--	and reset it else
	max_idx_mux <= 	max_idx_result(10 downto 0)	when (new_max = '1') else
					max_idx_val 	when ((valid_auto = '1') or (cycle_done = '1')) else
					(others => '0');

	--
	---
	---- DFFs
	---
	--

	-- Generate the sample clock and update the clock counter
	MakeSampleClock : process(clock)
	begin

		if (rising_edge(clock)) then

			-- Latch the muxes
			clk_counter 	<= clk_counter_mux;
			sample_clock 	<= sample_clock_mux;

		end if;

	end process MakeSampleClock;

	-- Increment the sample counter based off of the sample clock
	UpdateSampleCounter : process(sample_clock)
	begin

		if (rising_edge(sample_clock)) then
			-- Latch the muxes
			samp_counter 	<= samp_counter_mux;
			max_idx_val 	<= max_idx_mux;
			max_auto_val 	<= max_auto_mux;
			clk_div 		<= clk_div_mux;

			-- Latch whether or not we just had a maximum
			had_max 		<= new_max;

			-- Latch if we are done with the current cycle
			cycle_done		<= cycle_done_mux;

		end if;

	end process UpdateSampleCounter;

	--
	---
	---- Results!
	---
	--

	result_div <= clk_div;
	result_idx <= max_idx_val;

end architecture;


























