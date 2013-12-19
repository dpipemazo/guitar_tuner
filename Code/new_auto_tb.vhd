--
-- This is the test bench for the autocorrelation unit for the guitar tuner
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.autocorrelate;

-- Test bench entity declaration
entity new_auto_tb is 
end new_auto_tb;

-- Declare the architecture of the test bench
architecture TB_ARCHITECTURE of new_auto_tb is
	
	-- The autocorrelation component
	component AUTOCORRELATE is 

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
			max_idx : out std_logic_vector(8 downto 0); -- Index of sample which 
														-- had maximum autocorrelation
														-- value. Frequency is then
														-- equal to the sampling
														-- frequency divided by this value.
			done	: out std_logic						-- Signal which indicates that
														--	autocorrelation and sampling 
														-- is complete and that the data
		);
	end component;

	-- Signals to map to I/) of the component
	signal test_clock 		: std_logic;
	signal test_clk_div 	: std_logic_vector(13 downto 0);
	signal test_sample 		: std_logic_vector(1 downto 0);
	signal test_reset 		: std_logic;
	signal test_max_idx 	: std_logic_vector(8 downto 0);
	signal test_done 		: std_logic; 

	--Signal used to stop clock signal generators. should always be FALSE
    signal  END_SIM  :  BOOLEAN := FALSE;

begin

	-- Declare the unit under test
	UUT: AUTOCORRELATE
		port map(
			clock 		=> test_clock,
			clk_div 	=> test_clk_div,
			sample 		=> test_sample,
			reset 		=> test_reset,
			max_idx 	=> test_max_idx,
			done 		=> test_done
		);


	-- Make the system clock
	make_clock: process
	begin
        -- this process generates a 20 ns period, 50% duty cycle clock

        -- only generate clock while still have stimulus vectors

        if END_SIM = FALSE then
            test_clock <= '1';
            wait for 10 ns;
        else
            wait;
        end if;

        if END_SIM = FALSE then
            test_clock <= '0';
            wait for 10 ns;
        else
            wait;
        end if;

    end process;    -- end of clock process

    -- Make a quarter-sample sine wave
    make_sin: process
    begin

    	-- Make a 256-sample periodic sample and check it.

    	test_sample <= "01";
    	wait for 80 ns;

    	for i in 1 to 254 loop
	    	test_sample <= "00";
	    	wait for 80 ns;
	    end loop;

    	test_sample <= "11";
    	wait for 80 ns;
    end process;

    --
    -- Actually test the autocorrelation unit
    --
    do_test: process

    	-- Define variables here

    begin

    	-- Need to initialize all of our signals

    	-- Sample at 1/4 the rate of our system clock, so set 
    	--	the divided to 4
    	test_clk_div <= "00000000000100";

    	-- Set reset high for a bit to initialize everything
    	test_reset <= '1';

    	-- Wait for a bit to let it reset
    	wait for 250 ns;

    	-- Now, assert reset low and just visually inspect the results for now
    	test_reset <= '0';

    	while (test_done /= '1') loop
    		wait for 10 ns;
    	end loop;

    	wait for 1000 ns;

    	-- At this point, it should be done, so take a look at what we have
    end process;

end architecture;



































		
