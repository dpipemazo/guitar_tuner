--
-- This is the test bench for the autocorrelation unit for the guitar tuner.
--	If tests each string's predicted frequency as well as the upper and 
--	lower limits of the tolerance for each string to ensure that they are
--	detected correctly. The simulations are performed in "real time", 
--	so they do take a while, but use the same values as will be used 
--	in the real system. 
--
-- 12/20/13 -- Tests passing! Can detect frequencies from 25Hz to 
--              10Khz within 2 cents. (really 1ish cent)
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
            clock       : in std_logic;                     -- the system clock, 100MHz. 

            sample      : in std_logic_vector(1 downto 0);  -- sample input

            n_reset     : in std_logic;                     -- active high. Just needs 
                                                            --  to be high for one 
                                                            --  system (100 MHZ) clock
                                                            --  and it will begin a sampling
                                                            --  process

            -- Outputs
            result_div  : out std_logic_vector(11 downto 0);-- Divider used which gets
                                                            -- close to 1024xf_interest 

            result_idx  : out std_logic_vector(10 downto 0);-- Index of the sample
                                                            -- which had the maximum
                                                            -- autocorrelation value. Should
                                                            -- be close to 1024.

            done        : out std_logic                     -- Sampling is complete and the 
                                                            --  frequency has been found
        );

	end component;

	-- Signals to map to I/) of the component
	signal test_clock 		: std_logic;
	signal test_sample 		: std_logic_vector(1 downto 0);
	signal test_reset	: std_logic;
    signal test_result_div  : std_logic_vector(11 downto 0);
	signal test_result_idx	: std_logic_vector(10 downto 0);
	signal test_done 		: std_logic; 

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
			sample 	    => test_sample,
			reset 	    => test_reset,
			result_div 	=> test_result_div,
			result_idx 	=> test_result_idx,
			done 		=> test_done
		);


	-- Make the system clock
	make_clock: process

        variable END_SIM : boolean := FALSE;

	begin
        -- this process generates a 10 ps period, 50% duty cycle clock, 
        -- which is equivalent to the clock which we will have in our system. 
        if END_SIM = FALSE then
            test_clock <= '1';
            wait for 5 ps;
        else
            wait;
        end if;

        if END_SIM = FALSE then
            test_clock <= '0';
            wait for 5 ps;
        else
            wait;
        end if;
    end process;    -- end of clock process


    --
    -- Actually test the autocorrelation unit
    --
    do_test: process

    	-- Define variables here
        variable seed1, seed2 : positive;
    	variable sin_val, rand : real;
    	variable freq, freq_lo, freq_hi, reported_freq, rand_freq : real;
    	variable time_count : real;
        variable old_divider, new_divider : integer;
        variable END_SIM : boolean := FALSE;

    begin

        -- Test a random frequency. We want to sample at roughly 900 times the sample frequency, and stop
        --  once we are sufficiently close to this value. To accomplish this:
        --
        -- 1. Set the starting sampling frequency to 10MHz, which roughtly corresponds
        --  to 900 times the top of our range of interest. Run the autocorrelation unit.
        --  Once the unit says it is done, calculate the new divider by performing:
        --  
        --                          (old_divider * result_index)
        --                          ----------------------------
        --                                  900
        --
        -- This scales the divider towards the value which we want in a rapid manner. If the 
        --  result index from last time was 1, we are sampling too fast, so multiply the 
        --  old divider by 2 instead. 
        --
        -- This algorithm will converge once the new divider value is equal to the old divider value.
        --  At this point, the resulting frequency is equal to 100MHz/divider/result, and will
        --  be within 1.5 cents (guaranteed 2 cents if noise and such) of the correct result
        --

        -- Give the system a clock to reset itself
        wait for 20 ps;

        --
        -- Need to tell the system to reset
        --  So send reset high for a clock
        --  After this, it will continuously sample
        --  and the output can be latched into a FIFO.
        --  using the done signal
        --
        test_reset <= '0';
        wait for 20 ps;
        test_reset <= '1';

        while (END_SIM = FALSE) loop

            -- Get a random value on the interval [0,1].
            UNIFORM(seed1, seed2, rand);
            -- Map the random value to [25, 10000]
            rand_freq := rand*9975.0 + 25.0;

            -- Initialize the time to a random time
            UNIFORM(seed1, seed2, time_count);

            while (test_done = '1') loop
                wait for 10 ps;
            end loop;

            -- Now, just output the frequency until done 
            --  goes high
            while (test_done /= '1') loop

                -- Calculate the sine.
                sin_val := sin(MATH_2_PI*time_count*rand_freq*1000.0);

                if (sin_val > 0.8) then
                    test_sample <= "10";
                elsif (sin_val < -0.8) then
                    test_sample <= "11";
                else
                    test_sample <= "00";
                end if;

                -- Increment the time count and wait for 10 ps
                time_count := time_count + 0.00000000001;
                wait for 10 ps;

            end loop;

            -- Calculate the reported frequency by dividing the input clock (100MHz) by the result divider and index
            reported_freq  := 100000000.0/(real(to_integer(unsigned(test_result_div)))*real(to_integer(unsigned(test_result_idx))));

            -- See if we (1) got it right to 1 cent or (2) got a harmonic or (3) failed miserably
            if ( abs(1.0 - (rand_freq/reported_freq)) < 0.001156 ) then
                assert false report "SUCCESS: Frequency correctly detected to within 2 cents";
            elsif ( (abs(round(rand_freq/reported_freq) - (rand_freq/reported_freq)) < 0.01) and (round(rand_freq/reported_freq) > 1.5) ) then
                assert false report "ERROR: Reported Harmonic, not actual frequency";
            else
                assert false report "ERROR: Incorrectly detected frequency";
                END_SIM := TRUE;
            end if;

        end loop;

        --
        -- The code below is for testing the strings to 2 cent tolerance. It should
        --  not be used until updated for the new specs as of 12/19/2013
        --

    	-- -- Loop over all of the strings
    	-- for curr_string in string_tests loop

    	-- 	--
    	-- 	-- Map out the variables based on the frequency
    	-- 	--
    	-- 	if (curr_string = STRING_E2) then
    	-- 		test_clk_div <= std_logic_vector(to_unsigned(2370, test_clk_div'length));
    	-- 		freq := 82.41;

    	-- 	elsif (curr_string = STRING_A) then
    	-- 		test_clk_div <= std_logic_vector(to_unsigned(1776, test_clk_div'length));
    	-- 		freq := 110.0;

    	-- 	elsif (curr_string = STRING_D) then
    	-- 		test_clk_div <= std_logic_vector(to_unsigned(1330, test_clk_div'length));
    	-- 		freq := 146.8;

    	-- 	elsif (curr_string = STRING_G) then
    	-- 		test_clk_div <= std_logic_vector(to_unsigned(996, test_clk_div'length));
    	-- 		freq := 196.0;

    	-- 	elsif (curr_string = STRING_B) then
    	-- 		test_clk_div <= std_logic_vector(to_unsigned(791, test_clk_div'length));
    	-- 		freq := 246.9;

    	-- 	elsif (curr_string = STRING_E4) then
    	-- 		test_clk_div <= std_logic_vector(to_unsigned(593, test_clk_div'length));
    	-- 		freq := 329.6;

    	-- 	else 
    	-- 		test_clk_div <= std_logic_vector(to_unsigned(0, test_clk_div'length));
    	-- 		freq := 0.0;
    	-- 	end if;

     --        -- Need to reset at beginning of time. 
     --        test_reset <= '1';
     --        wait for 100 ns;
     --        test_reset <= '0';

    	-- 	-- Calculate freq_lo and freq_hi
    	-- 	freq_lo := 0.999*freq;
    	-- 	freq_hi := 1.001*freq;

     --        -- Wait for done to go back low if it's high
     --        while (test_done = '1') loop
     --            wait for 10 ns;
     --        end loop;
    	-- 	-- Initialize the time count
    	-- 	time_count := 0.0;

    	-- 	-- Test the actual frequency
    	-- 	while (test_done /= '1') loop

    	-- 		-- Calculate the sine.
    	-- 		sin_val := sin(MATH_2_PI*time_count*freq);

    	-- 		if (sin_val > 0.8) then
    	-- 			test_sample <= "10";
    	-- 		elsif (sin_val < -0.8) then
    	-- 			test_sample <= "11";
    	-- 		else
    	-- 			test_sample <= "00";
    	-- 		end if;

    	-- 		-- Increment the time count and wait for 10 ns
    	-- 		time_count := time_count + 0.00000001;
    	-- 		wait for 10 ns;

    	-- 	end loop;

    	-- 	-- Now, the done signal should be high. So assert that the bin was 512
    	-- 	assert(to_integer(unsigned(test_max_idx)) = 512) report "Did not correctly detect frequency";

     --        -- Wait for done to go back low
     --        while (test_done = '1') loop
     --            wait for 10 ns;
     --        end loop;
    	-- 	-- Initialize the time count
    	-- 	time_count := 0.0;

    	-- 	-- Test the frequency on the low side of the tolerance
    	-- 	while (test_done /= '1') loop

    	-- 		-- Calculate the sine.
    	-- 		sin_val := sin(MATH_2_PI*time_count*freq_lo);

    	-- 		if (sin_val > 0.8) then
    	-- 			test_sample <= "10";
    	-- 		elsif (sin_val < -0.8) then
    	-- 			test_sample <= "11";
    	-- 		else
    	-- 			test_sample <= "00";
    	-- 		end if;

    	-- 		-- Increment the time count and wait for 10 ns
    	-- 		time_count := time_count + 0.00000001;
    	-- 		wait for 10 ns;

    	-- 	end loop;

    	-- 	-- Now, the done signal should be high. So make sure that the bin is not 512
    	-- 	assert(to_integer(unsigned(test_max_idx)) /= 512) report "False positive on low bound";

     --        -- Wait for done to go back low
     --        while (test_done = '1') loop
     --            wait for 10 ns;
     --        end loop;
  	  --   	-- Initialize the time count
    	-- 	time_count := 0.0;

    	-- 	-- Test the frequency on the high side of the tolerance
    	-- 	while (test_done /= '1') loop

    	-- 		-- Calculate the sine.
    	-- 		sin_val := sin(MATH_2_PI*time_count*freq_hi);

    	-- 		if (sin_val > 0.8) then
    	-- 			test_sample <= "10";
    	-- 		elsif (sin_val < -0.8) then
    	-- 			test_sample <= "11";
    	-- 		else
    	-- 			test_sample <= "00";
    	-- 		end if;

    	-- 		-- Increment the time count and wait for 10 ns
    	-- 		time_count := time_count + 0.00000001;
    	-- 		wait for 10 ns;

    	-- 	end loop;

    	-- 	-- Now, the done signal should be high. So make sure that the bin is not 512
    	-- 	assert(to_integer(unsigned(test_max_idx)) /= 512) report "False positive on high bound";

    	-- end loop;

	end process;

end architecture;



































		
