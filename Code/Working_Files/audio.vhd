--
-- This is the code which will be used to perform 
--	sampling for the pitch detector system.
--
-- The samples will come at 48KHz from the AC97 driver. 
--	The AC97 driver will output a 48KHz clock which can be used
--	to clock the samples in. 
--
-- Samples come in at 48 KHz. The slowest signal which we are 
--	trying to detect is 25Hz. We want to perform absolute maximum
--	detection on the samples to see if we have a strong 
--	enough signal to run the algorithm. A 25 Hz signal will experience
--	a maximum approximately twice per cycle (at the max and the min). 
--	So, we need to perform maximum detection every 50 Hz. Essentially, 
--	every 50Hz, we need to zero out our maximum register, and then 
--	look at the next string of samples and record the maximum. If the
--	maximum is above some threshold, then we will use it, otherwise
--	we will say that the next string of samples is not valid.  
--
-- The samples coming out of this unit will be running at 48KHz. They
--	can be upsampled/downsampled without risk by the autocorrelation
--	algorithm. If it turns out to be a problem, then we can add 
--	a filter but we shouldn't need it. 

-- Libraries
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

library work;
use work.ac97_driver;

--
-- Declare the IO
--
entity AUDIO is 
	
	port(

		-- Inputs
		clock			: in std_logic;	-- the 100MHz clock
		n_reset			: in std_logic;	-- Active low reset

		-- Outputs for autocorrelation
		auto_sample	: out std_logic_vector(1 downto 0); 	-- The 48KHz sample bitstream, 
															-- thresholded and converted
															-- from 18-bits to 2 for the
															-- autocorrelation algorithm
		sample_valid	: out std_logic;					-- Whether the sample strength
															--	was high enough in the past
															--	50Hz checking algorithm 
															--	to run the autocorrelation
															--	algorithm off of.

		-- I/O for dealing with the codec
		raw_sample_out	: in std_logic_vector(17 downto 0); 	-- 18-bit samples to be sent to the codec
																--	will be clocked at 48KHz
		raw_sample_in	: out std_logic_vector(17 downto 0); 	-- 18-bit samples coming from the codec 
																--  will be clocked at 48KHz 
		play_samples	: in std_logic;							-- Active high. Turns playback on.
		play_output		: in std_logic;							-- 1 = line out, 0 = headphones

		-- Signals to be connected to I/O
		audsdi			: in std_logic;
		audsdo 			: out std_logic;
		sync			: out std_logic;
		audrst			: out std_logic;
		bitclk			: in std_logic

	);

end entity;

--
-- The architecture of the sampling unit
--
architecture behavioral of AUDIO is
	
	-- We need to hook up the ac97 unit
	signal codec_sample_r_out	: std_logic_vector(17 downto 0);
	signal codec_sample_l_out	: std_logic_vector(17 downto 0);
	signal codec_sample_r_in	: std_logic_vector(17 downto 0);
	signal codec_sample_l_in	: std_logic_vector(17 downto 0);

	-- Volume control. Eventually attach to switches
	signal volume_control 		: std_logic_vector(4 downto 0);
	signal source_control		: std_logic_vector(2 downto 0); -- 000 for mic, 100 for line in. 
																--	use mic unless debug.

	--
	-- Signals for finding a maximum and minimum
	--
	signal sync_clk_counter : std_logic_vector(9 downto 0); -- 10-bit counter divides down by 1024
	signal temp_max			: std_logic_vector(17 downto 0);
	signal temp_min			: std_logic_vector(17 downto 0);
	signal auto_sample_max		: std_logic_vector(17 downto 0);
	signal auto_sample_min		: std_logic_vector(17 downto 0);
	signal sample_avg		: std_logic_vector(17 downto 0);

	-- Signals for finsing the threshold
	signal sample_max_mult_result : std_logic_vector(20 downto 0);
	signal sample_min_mult_result : std_logic_vector(20 downto 0);
	signal sample_high_threshold  :	std_logic_vector(17 downto 0);
	signal sample_low_threshold	  : std_logic_vector(17 downto 0);

	-- Sync signal. Will be acting like a clock so let's buffer it
	signal 	  sync_clk	: std_logic;

	-- Signal to do the sample thresholding
	signal auto_sample_mux : std_logic_vector(1 downto 0);


begin

	--
	-- Need to pass the sync signal through as well
	--
	sync <= sync_clk;

	--
	-- Hook up the AC97 driver
	--
	ac97_unit : entity work.ac97_driver(behavioral)

		port map(
			n_reset        	=> n_reset,
			clk            	=> clock,
			play_samples	=> play_samples,
			play_output		=> play_output,
			L_out          	=> codec_sample_l_out,
			R_out          	=> codec_sample_r_out,
			L_in           	=> codec_sample_l_in,
			R_in           	=> codec_sample_r_in,
			volume			=> volume_control,
			source			=> source_control,
			audsdi			=> audsdi,
			audsdo 			=> audsdo,
			sync			=> sync_clk,
			audrst			=> audrst,
			bitclk			=> bitclk
		);

	--
	-- Set the volume to max for now, and set the source to mic
	--
	volume_control <= (others => '1');
	source_control <= (others => '0');

	--
	-- Map samples coming in and out to the I/O of this unit. Since
	--	the mic is mono, map both the output to L and R and map the 
	--	input to either L or R. 
	--
	codec_sample_l_out <= raw_sample_out;
	codec_sample_r_out <= raw_sample_out;
	raw_sample_in <= codec_sample_l_in;

	--
	-- Now need to do the 2-bit sample processing
	--

	-- First, need to do maximum detection to set the threshold for the next round of samples
	--	Samples are coming in at 48KHz. Our lowest expected frequency is 25ish Hz. 
	--	So we can expect to see a maximum every 50ish Hz. So, use a 1024 sample counter, 
	--	and record the maximum and the minimum. 
	--
	-- The maximum and minimum should be signed complements of each other. If they are not, 
	--	then calculate the difference and use it as a noise cancellation level. 
	--
	-- If the maximum is above the threshold for valid maximums, then 
	findMinMax: process(sync_clk)
	begin

		if (rising_edge(sync_clk)) then

			-- Need to deal with reset
			if (n_reset = '0') then 
				sync_clk_counter <= (others => '0');
				temp_max <= (others => '0');
				temp_min <= (others => '1');

			-- Else, not reset. We should be okay
			else

				-- Always increment the sync clock counter
				sync_clk_counter <= std_logic_vector(unsigned(sync_clk_counter) + 1);

				-- If the sync clock counter is at a maximum, then we need to
				--	output the max and min values
				if (std_match(sync_clk_counter, "1111111111")) then
					-- Clock the new max/min
					auto_sample_max <= temp_max;
					auto_sample_min <= temp_min;
					sample_avg <= std_logic_vector(signed(temp_max) + signed(temp_min));

					-- reset the temporary max/min
					temp_max <= (others => '0');	-- Reset the max to 0
					temp_min <= (others => '1');	-- Reset the min to -1

				-- Oterwise we just want to check for a new max/min
				else

					-- If we got a new max
					if (signed(codec_sample_l_in) > signed(temp_max)) then
						temp_max <= codec_sample_l_in;
					end if;

					-- If we got a new min. 
					if (signed(codec_sample_l_in) < signed(temp_min)) then
						temp_min <= codec_sample_l_in;
					end if;

				end if;

				--
				-- Latch the sample. The fist sample will be valid
				--	on the first sample clock after sample_valid is high.
				--
				auto_sample <= auto_sample_mux;

			end if;

		end if;

	end process;

	
	--
	-- Now that we have a min and a max over the past 50Hz, use these to determine
	--	thresholds for the samples. 
	--

	-- The streams of samples will be valid if the max is at least 20% of the maximum
	--	value for now. This may change. an 18-bit signed sample has a maximum
	-- 	of (2^17 - 1) = 131071, of which 20% is roughly 26,000. 16K is good enough, 
	--	since that is 14 bits, and random noise shouldn't be able to get above 
	--	the 13th bit (hopefully).
	sample_valid <= '1' when (signed(auto_sample_max) > to_signed(16384, auto_sample_max'length)) else
					'0';

	--
	-- Now compute the thresholds as 75% of the min and max, respectively. We will
	--	do a multiply by 3 and then a divide by 4. We don't really care about 
	--	rounding
	--

	-- Result will be 18 bits + 3 bits = 21 bits. 
	sample_max_mult_result <= std_logic_vector(signed(auto_sample_max) * to_signed(3, 3));
	sample_min_mult_result <= std_logic_vector(signed(auto_sample_min) * to_signed(3, 3));
	-- Now divide by 4 to get the threshold
	sample_high_threshold <= sample_max_mult_result(20 downto 3);
	sample_low_threshold <= sample_min_mult_result(20 downto 3);

	--
	-- And finally we can do our sample thresholding
	--
	auto_sample_mux <= "11" when (signed(codec_sample_l_in) < signed(sample_low_threshold)) else 	-- Sample below min thresh
						"01" when (signed(codec_sample_l_in) > signed(sample_high_threshold)) else 	-- Sample above max thresh
						"00" when (signed(codec_sample_l_in) > signed(sample_avg)) else				-- Sample not either of the above but above average
						"10";


end architecture;

