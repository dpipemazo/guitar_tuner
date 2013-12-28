--
-- This is the test bench for the tuner unit. 
--
-- This  test bench will use the autocorrelation unit, 
--	so make sure that the autocorrelation unit works
--	before proceeding to this test bench. It will also
--	use the frequency conversion unit
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.tuner;

-- Test bench entity declaration
entity tuner_tb is 
end tuner_tb;

-- Declare the architecture of the test bench
architecture TB_ARCHITECTURE of tuner_tb is


    -- The tuner component
    component TUNER is 
    	port(
	    	-- System clock and reset
			clk				: in std_logic; -- system clock
			n_reset			: in std_logic;

			run_motor		: in std_logic;	-- whether we should
											--	be running the motor or not
			-- The current string
			curr_string		: in std_logic_vector(2 downto 0); 	-- 000 = free tune, 
																-- 1 - 6 = EADGBE inthat order

			-- the frequency result
			div_quotient	: in std_logic_vector(13 downto 0);
			div_fractional	: in std_logic_vector(9 downto 0);
			new_data		: in std_logic;

			-- Stepper motor commands
			step			: out std_logic;
			dir				: out std_logic;

			-- Whether or not the frequency is in tune
			tuned			: out std_logic;
			-- Whether or not the unit is in the process of sending steps
			--	active low when in the process of stepping. 
			n_stepping		: out std_logic
		);
    end component;

    -- Signals to hook up the components
	signal test_clk				: std_logic;		
	signal test_n_reset			: std_logic;
	signal test_run_motor		: std_logic;
	signal test_curr_string		: std_logic_vector(2 downto 0);
	signal test_div_quotient	: std_logic_vector(13 downto 0);
	signal test_div_fractional	: std_logic_vector(9 downto 0);
	signal test_new_data		: std_logic;
	signal test_step			: std_logic;
	signal test_dir				: std_logic;
	signal test_tuned			: std_logic;
	signal test_n_stepping		: std_logic;

	-- type for the string
	type string_freqs is array(0 to 5) of real;
	constant strings : string_freqs := (82.407, 110.000, 146.832, 195.998, 246.942, 329.628);

	shared variable END_SIM : boolean := FALSE;

begin

	--
	-- Need to wire up the units under test
	--
	testTuner : TUNER
		port map(
			clk				=> test_clk,
			n_reset			=> test_n_reset,
			run_motor		=> test_run_motor,	
			curr_string		=> test_curr_string,	
			div_quotient	=> test_div_quotient,
			div_fractional	=> test_div_fractional,
			new_data		=> test_new_data,	
			step			=> test_step,		
			dir				=> test_dir,			
			tuned			=> test_tuned,		
			n_stepping		=> test_n_stepping
		);

	-- Make the system clock
	make_clock: process
	begin
        -- this process generates a 10 ns period, 50% duty cycle clock, 
        -- which is equivalent to the clock which we will have in our system. 
        if END_SIM = FALSE then
            test_clk <= '1';
            wait for 5 ns;
        else
            wait;
        end if;

        if END_SIM = FALSE then
            test_clk <= '0';
            wait for 5 ns;
        else
            wait;
        end if;
    end process;    -- end of clock process

	--
	-- Now do the actual test. Test each string by performing the following
	--	sequence of events:
	--
	--	1. Generate a random frequency within +/- 50% of the string's
	--		frequency.
	--	2. Generate a random real number between 20 and 50 which represents
	--		the approximate number of steps per Hz for the string. 
	--	3. Generate samples at the random frequency. After the 
	--		stepper outputs its steps, update the frequency my 
	--		calculating freq = freq + dir*steps/(steps/hz) where dir = +/- 1
	--	4. Continue until the string is at the correct frequency.
	--
	do_test : process
		variable string_idx : integer range 0 to 5;
		variable string_freq : real;
		variable rand_step_hz, reported_freq 	: real;
		variable rand 		 	: real;
		variable seed1, seed2 	: positive;

	begin

		-- Initialize everything
		string_idx := 0;
		-- Want to run the motor
		test_run_motor <= '1';

		-- Send the system reset immediately to stop the divider from complaining
		test_n_reset <= '0';
		wait for 10 ns;	-- Need the step clock to go high
		test_n_reset <= '1';

		-- Now loop, testing each of the strings
		while (END_SIM = FALSE) loop

			-- Change the current string
			test_curr_string <= std_logic_vector(to_unsigned(string_idx + 1, test_curr_string'length));

			-- Generate a random value between 0.5 and 1.5 times the 
			--	current string's frequency for the random frequency
			UNIFORM(seed1, seed2, rand);
			string_freq := (rand + 0.5)*strings(string_idx);
			-- Generate another random value between 20 and 50 for the 
			--	number of steps/Hz inrement
			UNIFORM(seed1, seed2, rand);
			rand_step_hz := 30.0*rand + 20.0;

			--
			-- Now that we have our random starting frequency and our random
			--	string constant, we need to run the algorithm to completion and
			--	see if the string gets tuned
			--
			while (TRUE) loop

				-- Put the frequency data out for the tuner unit
				test_div_quotient <= std_logic_vector(to_unsigned(integer(trunc(string_freq)), test_div_quotient'length));
				test_div_fractional <= std_logic_vector(to_unsigned(integer(trunc((string_freq - trunc(string_freq))*1024.0)), test_div_fractional'length));
				
				-- Let the data be valid and then tell the tuning unit 
				--	that the data is valid
				wait for 10 ns;
				test_new_data <= '1';
				wait for 10 ns;
				test_new_data <= '0';

				wait for 10 ns;
				-- Check for tuned here, and if it is tuned then break out of the loop. It's
				--	kind of an awkward setup to break out, but that's how it's gotta be.
				if (test_tuned = '1') then
					exit;
				end if;

	            --
	            -- Now, wait for the stepping to begin
	            --
	   			while(test_n_stepping /= '0') loop
	   				wait for 10 ns;
	   			end loop;

	   			-- Once the stepping has begun, adjust the sample frequency 
	   			--	after each step
	   			while(test_n_stepping = '0') loop
	   				if (test_step = '1') then
	   					if (test_dir = '1') then
	   						string_freq := string_freq + (1.0/rand_step_hz);
	   					else
	   						string_freq := string_freq - (1.0/rand_step_hz);
	   					end if;

	   					while(test_step = '1') loop
	   						wait for 10 ns;
	   					end loop;
	   				else
	   					wait for 10 ns;
	   				end if;
	   			end loop;

	   		end loop;

   			-- Make sure that the frequency which we have after tuning is within
   			--	5 hz of the real frequency.
			if ( abs(1.0 - (string_freq/strings(string_idx))) < 0.0029 ) then
                assert false report "SUCCESS: String correctly tuned to within to within 5 cents";
            else
                assert false report "ERROR: String incorrectly tuned";
                END_SIM := TRUE;
            end if;

            -- Wait for the tuned signal to drop
            wait for 10 ns;

            if(string_idx = 5) then
            	string_idx := 0;
            else
            	string_idx := string_idx + 1;
            end if;

        end loop;

    end process;

end architecture;






