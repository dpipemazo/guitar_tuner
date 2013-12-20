--
-- This is the test bench for the autocorrelation unit for the guitar tuner.
--	If tests each string's predicted frequency as well as the upper and 
--	lower limits of the tolerance for each string to ensure that they are
--	detected correctly. The simulations are performed in "real time", 
--	so they do take a while, but use the same values as will be used 
--	in the real system. 
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
			clk_div	: in std_logic_vector(12 downto 0); -- Divider from system clock
														--	to create the sample clock
														-- 	from. 13 bits allows
														--	from frequencies from ~25Hz 
														--	and up to be detected. Assumes
														--	system clock is 100MHz.
			sample  : in std_logic_vector(1 downto 0);	-- sample input
			reset   : in std_logic;						-- active high. System will run
														--  as long as this is low, else
														--	will stay in a reset state, 

			-- Output
			max_idx : out std_logic_vector(9 downto 0); -- Index of sample which 
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
	signal test_clk_div 	: std_logic_vector(12 downto 0);
	signal test_sample 		: std_logic_vector(1 downto 0);
	signal test_reset 		: std_logic;
	signal test_max_idx 	: std_logic_vector(9 downto 0);
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
    	variable freq, freq_lo, freq_hi : real;
    	variable time_count : real;

    begin

        -- Need to reset at beginning of time. 
        test_reset <= '1';
        wait for 100 ns;
        test_reset <= '0';


    	-- Loop over all of the strings
    	for curr_string in string_tests loop

    		--
    		-- Map out the variables based on the frequency
    		--
    		if (curr_string = STRING_E2) then
    			test_clk_div <= std_logic_vector(to_unsigned(2370, test_clk_div'length));
    			freq := 82.41;

    		elsif (curr_string = STRING_A) then
    			test_clk_div <= std_logic_vector(to_unsigned(1776, test_clk_div'length));
    			freq := 110.0;

    		elsif (curr_string = STRING_D) then
    			test_clk_div <= std_logic_vector(to_unsigned(1330, test_clk_div'length));
    			freq := 146.8;

    		elsif (curr_string = STRING_G) then
    			test_clk_div <= std_logic_vector(to_unsigned(996, test_clk_div'length));
    			freq := 196.0;

    		elsif (curr_string = STRING_B) then
    			test_clk_div <= std_logic_vector(to_unsigned(791, test_clk_div'length));
    			freq := 246.9;

    		elsif (curr_string = STRING_E4) then
    			test_clk_div <= std_logic_vector(to_unsigned(593, test_clk_div'length));
    			freq := 329.6;

    		else 
    			test_clk_div <= std_logic_vector(to_unsigned(0, test_clk_div'length));
    			freq := 0.0;
    		end if;

    		-- Calculate freq_lo and freq_hi
    		freq_lo := 0.995*freq;
    		freq_hi := 1.005*freq;

            -- Wait for done to go back low if it's high
            while (test_done = '1') loop
                wait for 10 ns;
            end loop;
    		-- Initialize the time count
    		time_count := 0.0;

    		-- Test the actual frequency
    		while (test_done /= '1') loop

    			-- Calculate the sine.
    			sin_val := sin(MATH_2_PI*time_count*freq);

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

    		-- Now, the done signal should be high. So assert that the bin was 512
    		assert(to_integer(unsigned(test_max_idx)) = 512) report "Did not correctly detect frequency";

            -- Wait for done to go back low
            while (test_done = '1') loop
                wait for 10 ns;
            end loop;
    		-- Initialize the time count
    		time_count := 0.0;

    		-- Test the frequency on the low side of the tolerance
    		while (test_done /= '1') loop

    			-- Calculate the sine.
    			sin_val := sin(MATH_2_PI*time_count*freq_lo);

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

    		-- Now, the done signal should be high. So make sure that the bin is not 512
    		assert(to_integer(unsigned(test_max_idx)) /= 512) report "False positive on low bound";

            -- Wait for done to go back low
            while (test_done = '1') loop
                wait for 10 ns;
            end loop;
  	    	-- Initialize the time count
    		time_count := 0.0;

    		-- Test the frequency on the high side of the tolerance
    		while (test_done /= '1') loop

    			-- Calculate the sine.
    			sin_val := sin(MATH_2_PI*time_count*freq_hi);

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

    		-- Now, the done signal should be high. So make sure that the bin is not 512
    		assert(to_integer(unsigned(test_max_idx)) /= 512) report "False positive on high bound";

    	end loop;

	end process;

end architecture;



































		
