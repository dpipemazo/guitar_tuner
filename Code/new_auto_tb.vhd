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
			max_idx : out std_logic_vector(7 downto 0); -- Index of sample which 
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
	signal test_max_idx 	: std_logic_vector(7 downto 0);
	signal test_done 		: std_logic; 

	--Signal used to stop clock signal generators. should always be FALSE
    signal  END_SIM  :  BOOLEAN := FALSE;

    --
    -- OPCODE TYPE DEFINITION ENUM
    --
    type string_tests is(
        STRING_E2,
        STRING_A,
        STRING_D,
        STRING_B,
        STRING_G,
        STRING_E4
    );

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
        -- this process generates a 10 ns period, 50% duty cycle clock, 
        -- which is equivalent to the clock which we will have in our system. 
        if END_SIM = FALSE then
            test_clock <= '1';
            wait for 5 ns;
        else
            wait;
        end if;

        if END_SIM = FALSE then
            test_clock <= '0';
            wait for 5 ns;
        else
            wait;
        end if;
    end process;    -- end of clock process


    --
    -- Actually test the autocorrelation unit
    --
    do_test: process

    	-- Define variables here
    	variable sin_val : real;
    	variable freq : real;
    	variable time_count : real;
    	variable sin_val : real;

    begin

	    -- Loop forever
	    while (END_SIM = FALSE) loop

	    	-- Loop over all of the strings
	    	for curr_string in string_tests loop

	    		--
	    		-- Map out the variables based on the frequency
	    		--
	    		if (curr_string = STRING_E2) then
	    			test_clk_div <= std_logic_vector(9480, test_clk_div'length);
	    			freq := 82.41;

	    		elsif (curr_string = STRING_A) then
	    			test_clk_div <= std_logic_vector(7102, test_clk_div'length);
	    			freq := 110.0;

	    		elsif (curr_string = STRING_D) then
	    			test_clk_div <= std_logic_vector(5322, test_clk_div'length);
	    			freq := 146.8;

	    		elsif (curr_string = STRING_G) then
	    			test_clk_div <= std_logic_vector(3986, test_clk_div'length);
	    			freq := 196.0;

	    		elsif (curr_string = STRING_B) then
	    			test_clk_div <= std_logic_vector(3164, test_clk_div'length);
	    			freq := 246.9;

	    		elsif (curr_string = STRING_E4) then
	    			test_clk_div <= std_logic_vector(2370, test_clk_div'length);
	    			freq := 329.6;

	    		else 
	    			test_clk_div <= std_logic_vector(0, test_clk_div'length);
	    			freq := 0;
	    		end if;

	    		-- Assert the reset for a few clocks to clear everything
	    		test_reset <= '1';

	    		wait for 50 ns;

	    		-- Initialize reset and the time count;
	    		test_reset <= '0';
	    		time_count := 0;

	    		-- Generate samples at the desired frequency until it is done
	    		while (test_done /= '1') loop

	    			-- Calculate the sine.
	    			sin_val := sin(2*MATH_2_PI*time_count*freq);

	    			if (sin_val > 0.8) then
	    				test_sample <= "10";
	    			elsif (sin_val < -0.8) then
	    				test_sample <= "11";
	    			else
	    				test_sample <= "00";
	    			end if;

	    			-- Increment the time count and wait for 10 ns
	    			time_count := time_count + 0.00000001;
	    			wait for 10 ns;

	    		end loop;

	    		-- Now, the done signal should be high. So assert that the bin was 128
	    		assert(to_integer(test_max_idx) = 128) report "Did not correctly detect frequency";

	    	end loop;

	    end loop;

	end process;

end architecture;


--     	-- Need to initialize all of our signals

--     	-- Sample at 1/4 the rate of our system clock, so set 
--     	--	the divided to 4
--     	test_clk_div <= "00000000000100";

--     	-- Set reset high for a bit to initialize everything
--     	test_reset <= '1';

--     	-- Wait for a bit to let it reset
--     	wait for 250 ns;

--     	-- Now, assert reset low and just visually inspect the results for now
--     	test_reset <= '0';

--     	while (test_done /= '1') loop
--     		wait for 10 ns;
--     	end loop;

--     	wait for 1000 ns;

--     	-- At this point, it should be done, so take a look at what we have
--     end process;

-- end architecture;



































		
