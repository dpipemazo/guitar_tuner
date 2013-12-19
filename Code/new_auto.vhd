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
--  reset should just be passed through, no latching. If reset is high, 
--		set the clock counter to 0, else increment it. 
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

	-- Finally, DFF the registers on the rising edge of the clock
	doDFF	: process(clock)
	begin

		-- DFF all of the registers based on the clock. 
		if (rising_edge(clock)) then
			-- Put the appropriate value in register 1 based on the mux
			register_1 <= reg_1_mux;
			-- Always put the input sample in register 2
			register_2 <= sample_in;
			-- Always output register 2 as the sample output
			sample_out <= register_2;
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
		clock 	: in std_logic;						-- the system clock, 100MHz. 
		clk_div	: in std_logic_vector(13 downto 0); -- Divider from system clock
													--	to create the sample clock
													-- 	from. 14 bits allows
													--	from frequencies from ~50Hz 
													--	and up to be detected. Assumes
													--	system clock is 100MHz.
		sample  : in std_logic_vector(1 downto 0);	-- sample input
		reset   : in std_logic;						-- active high. System will run
													--  as long as this is low, else
													--	will stay in a reset state, 

		-- Output
		max_idx : out std_logic_vector(7 downto 0); -- Index of sample which 
													-- had maximum autocorrelation
													-- value. Frequency is then
													-- equal to the sampling
													-- frequency divided by this value.
		done	: out std_logic						-- Signal which indicates that
													--	autocorrelation and sampling 
													-- is complete and that the data
													--	on max_idx is valid
	);

end AUTOCORRELATE;

--
-- This is the architecture to the entire autocorrelation block. 
--
-- The architecture needs to assemble 256 of the SINGLE_AUTO blocks
--	and connect their I/O in series. The sample input of this block
--	will be fed into the final SINGLE_AUTO block in the array. 
--
-- The auto_out signals of the SINGLE_AUTO blocks need to be summed. 
--	This will be done through 128 2-bit adders of adjacent blocks, 
--	followed by 64 3-bit adders of adjacent 2-bit adders, etc. etc. 
--	until a single sum is obtained. This will hopefully create 
--	minimal signal routing issues and will essentially perform a
--	hamming weight algorithm. It will then compare the current 
--	sum of 1s to the known maximum. If the current sum is greater, 
--	then it will become the known maximum and max_idx will be set 
-- 	to the current autocorrelation value. 
--
-- The system will take a 14-bit divider as an input. This will be the 
--	comparator for when to sample. It will use an internal counter which
--	will wrap around the divider value. When the counter is equal to 0,
--	it will send the sample clock high for one system clock.
--
-- This block will take the "go" signal as an indication to begin sampling, 
--	and then will assert the "done" signal when done sampling.
--
architecture behavioral of AUTOCORRELATE is 
	
	-- Counter for the system. Measures out the 512 sample clock
	--	cycle which the system runs on. It is a 10-bit counter
	--	so that the top bit can be the "done" signal
	signal samp_counter : std_logic_vector(9 downto 0);
	-- Mux result for the counter
	signal samp_counter_mux : std_logic_vector(9 downto 0); 

	-- Declare our sample clock as a clock
	signal sample_clock : std_logic;
	signal sample_clock_mux : std_logic;
	-- Declare the buffer_type itself
   	attribute buffer_type : string;
	attribute buffer_type of sample_clock : signal is "BUFG";
	-- Counter for our sample clock
	signal clk_counter 		: std_logic_vector(13 downto 0);
	signal clk_counter_mux 	: std_logic_vector(13 downto 0);
	signal clk_counter_inc  : std_logic_vector(13 downto 0);

	-- Signals to link together the autocorrelation units
	type sample_array 	is array(512 downto 0) of std_logic_vector(1 downto 0);
	signal samples 		: sample_array;
	signal ops 			: std_logic_vector(512 downto 0);
	signal autos 		: std_logic_vector(511 downto 0);

	-- Signals to do the hamming weight addition
	type hamming_1 is array(127 downto 0) 	of std_logic_vector(1 downto 0);
	type hamming_2 is array(63 downto 0) 	of std_logic_vector(2 downto 0);
	type hamming_3 is array(31 downto 0)	of std_logic_vector(3 downto 0);
	type hamming_4 is array(15 downto 0)	of std_logic_vector(4 downto 0);
	type hamming_5 is array(7 downto 0)		of std_logic_vector(5 downto 0);
	type hamming_6 is array(3 downto 0)		of std_logic_vector(6 downto 0);
	type hamming_7 is array(1 downto 0)		of std_logic_vector(7 downto 0);

	signal hamming_1s : hamming_1;
	signal hamming_2s : hamming_2;
	signal hamming_3s : hamming_3;
	signal hamming_4s : hamming_4;
	signal hamming_5s : hamming_5;
	signal hamming_6s : hamming_6;
	signal hamming_7s : hamming_7;
	signal final_hamming : std_logic_vector(8 downto 0);

	-- Signals for computing the maximum autocorrelation value and storing
	--	its index
	signal max_idx_mux 		: std_logic_vector(7 downto 0);
	signal max_idx_val		: std_logic_vector(7 downto 0);
	signal max_auto_mux		: std_logic_vector(8 downto 0);
	signal max_auto_val 	: std_logic_vector(8 downto 0);	
	signal new_max			: std_logic;

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
	---- CLOCKING LOGIC
	---
	--

	-- First, need to do the logic for the go and done signals.
	--	The "done" signal is the top bit of the system counter, 
	--	which will be set after 512 system clocks have been executed, and will remain asserted
	--	for a single sample cycle.
	done <= samp_counter(9);

	-- Reset the counter when we either reach the maximum count or 
	--	our run signal is high
	samp_counter_mux <= (others => '0') when ((samp_counter(9) = '1') or (reset = '1')) else
						std_logic_vector(unsigned(samp_counter) + 1);

	-- Incremented cock counter value. This needs to be broken out since we will
	--	be using it to wrap around the divider value.
	clk_counter_inc <= std_logic_vector(unsigned(clk_counter) + 1);
	-- If the current counter + 1 == the divider, need to wrap around, else just increment
	--	the counter
	clk_counter_mux <= 	(others => '0') when (std_match(clk_counter_inc, clk_div) or (reset = '1')) else
						clk_counter_inc;
	-- Create the sample clock. High for a single system clock pulse when 
	--	the clock counter is 0, else low.
	sample_clock_mux <= '1' when std_match(clk_counter, "00000000000000") else
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
	-- Set the operation equal to bit 9 of the counter. Bit 9 will be
	--	high after 256 iterations, and will stay high until reset. 
	ops(0) 		<= samp_counter(9);

	-- First, string together autocorrelation units
	genautos: for i in 0 to 511 generate 
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
	genham1s: for i in 0 to 127 generate
	begin
		-- Couldn't figure out how to to a single add of bits, so just do it myself without the 
		--	need for an adder. 
		hamming_1s(i)(0) <= autos(2*i) xor autos(2*i + 1);
		hamming_1s(i)(1) <= autos(2*i) and autos(2*i + 1);
	end generate genham1s;

	genham2s: for i in 0 to 63 generate
	begin
		hamming_2s(i) <= std_logic_vector(("0" & unsigned(hamming_1s(2*i))) + ("0" & unsigned(hamming_1s(2*i + 1))));
	end generate genham2s;

	genham3s: for i in 0 to 31 generate
	begin
		hamming_3s(i) <= std_logic_vector(("0" & unsigned(hamming_2s(2*i))) + ("0" & unsigned(hamming_2s(2*i + 1))));
	end generate genham3s;

	genham4s: for i in 0 to 15 generate
	begin
		hamming_4s(i) <= std_logic_vector(("0" & unsigned(hamming_3s(2*i))) + ("0" & unsigned(hamming_3s(2*i + 1))));
	end generate genham4s;

	genham5s: for i in 0 to 7 generate
	begin
		hamming_5s(i) <= std_logic_vector(("0" & unsigned(hamming_4s(2*i))) + ("0" & unsigned(hamming_4s(2*i + 1))));
	end generate genham5s;

	genham6s: for i in 0 to 3 generate
	begin
		hamming_6s(i) <= std_logic_vector(("0" & unsigned(hamming_5s(2*i))) + ("0" & unsigned(hamming_5s(2*i + 1))));
	end generate genham6s;

	genham7s: for i in 0 to 1 generate
	begin
		hamming_7s(i) <= std_logic_vector(("0" & unsigned(hamming_6s(2*i))) + ("0" & unsigned(hamming_6s(2*i + 1))));
	end generate genham7s;

	-- Put together the final adder, and then we have our value!
	final_hamming <= std_logic_vector(("0" & unsigned(hamming_7s(0))) + ("0" & unsigned(hamming_7s(1))));

	--
	---
	---- MAXIMUM ITERATION LOGIC
	---
	--

	-- Here, we need to compare the current value of final_hamming to the 
	--	known maximum. If the current value is greater, then it becomes the
	--	maximum and max_idx is set to the current value of the sample clock.
	new_max <= 	'1' when (unsigned(final_hamming) > unsigned(max_auto_val)) else
				'0';

	-- Want max_auto to be 0 when not in the final 256 clocks, 
	max_auto_mux <= final_hamming 	when ((new_max = '1') and (samp_counter(8) = '1')) else
					max_auto_val	when ((samp_counter(8) = '1') or (samp_counter(9) = '1')) else
					(others => '0');

	max_idx_mux <= 	samp_counter(7 downto 0) 	when ((new_max = '1') and (samp_counter(8) = '1')) else
					max_idx_val 				when ((samp_counter(8) = '1') or (samp_counter(9) = '1')) else
					(others => '0');

	-- Now, output the maximum index 
	max_idx <= max_idx_val;	

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
		end if;

	end process UpdateSampleCounter;

end architecture;


























