--
-- This is a test bench for the frequency conversion module. should
--	be pretty straightforward. 
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.freq_convert;

-- Test bench entity declaration
entity freq_convert_tb is 
end freq_convert_tb;

-- Declare the architecture of the test bench
architecture TB_ARCHITECTURE of freq_convert_tb is
	
	-- The autocorrelation component
	component FREQ_CONVERT is 
		
		port(
			-- System clock 
			clk 		: in std_logic;						-- system clock

			-- Results from the audio unit
			divider		: in std_logic_vector(11 downto 0); -- auto divider
			bin			: in std_logic_vector(10 downto 0); -- auto result
			sample_done : in std_logic;

			-- Output to the display FIFO
			disp_wr_en	: out std_logic;					-- active high
			disp_data	: out std_logic_vector(15 downto 0) -- data to be written to FIFO

		);

	end component;

	-- Signals to hook up the the conversion unit
	signal test_clk 		: std_logic;
	signal test_divider 	: std_logic_vector(11 downto 0);
	signal test_bin			: std_logic_vector(10 downto 0);
	signal test_sample_done : std_logic;
	signal test_disp_wr_en 	: std_logic;
	signal test_disp_data 	: std_logic_vector(15 downto 0);


begin

	-- Declare the UUT
	UUT: FREQ_CONVERT
		port map(
			clk 		=> test_clk, 		
			divider		=> test_divider,		
			bin			=> test_bin,			
			sample_done => test_sample_done, 
			disp_wr_en	=> test_disp_wr_en,	
			disp_data	=> test_disp_data	
		);

	-- Make the system clock
	make_clock: process
	begin
        -- this process generates a 10 ps period, 50% duty cycle clock, 
        -- which is equivalent to the clock which we will have in our system. 
        test_clk <= '1';
        wait for 5 ps;

        test_clk <= '0';
        wait for 5 ps;

    end process; 

    --
    -- Actually test the frequency conversion unit
    -- 
    do_test: process

    	-- Need a random divider and bin
    	variable divider, bin : integer;
    	-- Need seeds for the random generator
    	variable seed1, seed2 : positive;
    	-- Need a real for the random variable
    	variable rand : real;
    	-- Loop unti this goes false
    	variable END_SIM : boolean := FALSE;

    begin

    	-- Loop until end sim is no longer valid
    	while (END_SIM = FALSE) loop

            -- Get a random value on the interval [0,1].
            UNIFORM(seed1, seed2, rand);
            -- calculate the expected divider, range [10, 4095]
            divider := integer(round(rand*4085 + 10));
            -- Get a random value on the interval [0,1].
            UNIFORM(seed1, seed2, rand);
            -- calculate the expected bin, range [980, 1050]
            bin := integer(round(rand*70 + 980));

            --
            -- Put the bin and divider on the line and send the done flag high
            --
            test_divider <= std_logic_vector(to_unsigned(divider, test_divider'length));
            test_bin <= std_logic_vector(to_unsigned(bin, test_bin'length));
            sample_done <= '1';

            -- wait for a clock
            wait for 10 ps;

            -- send the sample done signal low
            sample_done <= '0';

            -- Wait for 100 clocks
            wait for 1000 ps;

        end loop;

    end process;

end architecture;



