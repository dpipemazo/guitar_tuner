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
use work.pkg_dc97.all;

--
-- Declare the IO
--
entity AUDIO is 
	
	port(

		-- Inputs
		clk				: in std_logic;	-- the 100MHz clock
		n_reset			: in std_logic;	-- Active low reset

		-- Outputs for autocorrelation
		auto_sample		: out std_logic_vector(1 downto 0); -- The 48KHz sample bitstream, 
															-- thresholded and converted
															-- from 18-bits to 2 for the
															-- autocorrelation algorithm
		sample_valid	: out std_logic;					-- Whether the sample strength
															--	was high enough in the past
															--	50Hz checking algorithm 
															--	to run the autocorrelation
															--	algorithm off of.

		-- Signals to be connected to I/O
		audsdi			: in std_logic;
		audsdo 			: out std_logic;
		sync			: out std_logic;
		audrst			: out std_logic;
		bitclk			: in std_logic;

		-- Source and Volume Selects
		source			: in std_logic; -- 1 == line in, 0 == mic
		volume			: in std_logic_vector(4 downto 0)

	);

end entity;

--
-- The architecture of the sampling unit
--
architecture behavioral of AUDIO is

	--
	-- Signals for finding a maximum and minimum
	--
	signal sync_clk_counter : std_logic_vector(9 downto 0); -- 10-bit counter divides down by 1024
	signal temp_max			: std_logic_vector(17 downto 0);
	signal temp_min			: std_logic_vector(17 downto 0);
	signal auto_sample_max		: std_logic_vector(17 downto 0);
	signal auto_sample_min		: std_logic_vector(17 downto 0);

	-- Signals for finsing the threshold
	signal sample_high_threshold  	: std_logic_vector(17 downto 0);
	signal sample_low_threshold	  	: std_logic_vector(17 downto 0);
	signal sample_amplitude			: std_logic_vector(17 downto 0);

	-- Sync signal. Will be acting like a clock so let's buffer it
	signal sync_clk	: std_logic;

	-- Signal to do the sample thresholding
	signal auto_sample_mux : std_logic_vector(1 downto 0);

	-- Signals to hook up the ac97 unit
	signal ac97_sample_r_in	: std_logic_vector(17 downto 0);
	signal ac97_sample_l_in	: std_logic_vector(17 downto 0);
	signal ac97_rdy			: std_logic;
	signal ac97_cmd_addr	: std_logic_vector(7 downto 0);
	signal ac97_cmd_data	: std_logic_vector(15 downto 0);

	-- Need a signal to do the source selection since we only
	--	care about one bit
	signal source_sig : std_logic_vector(2 downto 0);


begin

	--
	-- Need to pass the sync signal through as well
	--
	sync <= sync_clk;

	--
	-- Hook up the entity that will drive the AC97 connection
	--
	ac97_main: entity work.dc97 
		port map(
	      n_reset      => n_reset,
	      clk          => clk,
	      ac97_sdata_o => audsdo,
	      ac97_sdata_i => audsdi,
	      ac97_sync    => sync_clk,
	      ac97_bitclk  => bitclk,
	      ac97_reset   => audrst,
	      ready        => ac97_rdy,
	      L_o          => ac97_sample_l_in, -- For debug purposes, just
	      R_o          => ac97_sample_r_in,	-- feed the input back out for
	      L_i          => ac97_sample_l_in, -- the time being
	      R_i          => ac97_sample_r_in,
	      cmd_addr     => ac97_cmd_addr,
	      cmd_data     => ac97_cmd_data
		);

	--
	-- Hook up the state machine that helps 
	--
	ac97_state: entity work.dc97cmd
		port map(
	      clk      => clk,
	      ready    => ac97_rdy,
	      cmd_addr => ac97_cmd_addr,
	      cmd_data => ac97_cmd_data,
	      volume   => volume,
	      source   => source_sig
		);

	-- Map the incoming source bit to the high bit of the source signal
	source_sig <= source & "00";

	--
	--
	-- Now need to do the 2-bit sample processing
	--
	--

	-- First, need to do maximum detection to set the threshold for the next round of samples
	--	Samples are coming in at 48KHz. Our lowest expected frequency is 25ish Hz. 
	--	So we can expect to see a maximum every 50ish Hz. So, use a 1024 sample counter, 
	--	and record the maximum and the minimum. 
	--
	-- If the maximum is above the threshold for valid maximums, then
	--
	-- NOTE: we are only looking at the left input sample right now. If we 
	--	use the mic input, then the left is the same as the right and it should 
	--	be fine. Line out of the frequency generator should also create
	--	an equally balanced signal so again it should be fine. Time will tell. 
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

					-- reset the temporary max/min
					temp_max <= (others => '0');	-- Reset the max to 0
					temp_min <= (others => '1');	-- Reset the min to the maximum

				-- Oterwise we just want to check for a new max/min
				else

					-- If we got a new max
					if (unsigned(ac97_sample_l_in) > unsigned(temp_max)) then
						temp_max <= ac97_sample_l_in;
					end if;

					-- If we got a new min
					if (unsigned(ac97_sample_l_in) < unsigned(temp_min)) then
						temp_min <= ac97_sample_l_in;
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

	--
	-- Compute the amplitude of the sample stream by doing the 
	--	max minus the min
	--
	sample_amplitude <= std_logic_vector(unsigned(auto_sample_max) - unsigned(auto_sample_min));
	--
	-- Now compute the thresholds by subtracting amplitude/8 from the max and adding
	--	amplitude/8 to the min
	--

	-- Now divide by 4 to get the threshold
	sample_high_threshold 	<= std_logic_vector(unsigned(auto_sample_max) - to_unsigned(1024, auto_sample_max'length));
	sample_low_threshold 	<= std_logic_vector(unsigned(auto_sample_min) + to_unsigned(1024, auto_sample_max'length));

	-- Make the sample valid when we have maxed out the ADC of the sampler
	sample_valid <= '1' when ( unsigned(sample_amplitude) > (2**17) ) else
					'0';
	--
	-- And finally we can do our sample thresholding
	--
	auto_sample_mux <= 	"11" when (unsigned(ac97_sample_l_in) < unsigned(sample_low_threshold)) else 	-- Sample below min thresh
						"01" when (unsigned(ac97_sample_l_in) > unsigned(sample_high_threshold)) else 	-- Sample above max thresh
						"00";


end architecture;

