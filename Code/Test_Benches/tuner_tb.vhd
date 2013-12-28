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
use work.autocorrelate;
use work.tuner;
use work.freq_convert;

-- Test bench entity declaration
entity tuner_tb is 
end tuner_tb;

-- Declare the architecture of the test bench
architecture TB_ARCHITECTURE of tuner_tb is

	-- The autocorrelation component
	component AUTOCORRELATE is 
        port (
            -- Inputs
            clk       	: in std_logic; 
            sample      : in std_logic_vector(1 downto 0); 
            n_reset     : in std_logic;
            result_div  : out std_logic_vector(11 downto 0);
            result_idx  : out std_logic_vector(10 downto 0);
            done        : out std_logic                     
                                                            
        );
    end component;

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

    -- The frequency conversion component
	component FREQ_CONVERT is 
		
		port(
			-- System clock 
			clk 		: in std_logic;						-- system clock

			-- Results from the audio unit
			divider		: in std_logic_vector(11 downto 0); -- auto divider
			bin			: in std_logic_vector(10 downto 0); -- auto result
			sample_done : in std_logic;

			-- Output to the display FIFO
			disp_wr_en	: out std_logic;					 -- active high
			disp_data	: out std_logic_vector(15 downto 0); -- data to be written to FIFO

			-- Output frequency to the motors unit
			quot_out	: out std_logic_vector(13 downto 0);
			frac_out	: out std_logic_vector(9 downto 0);
			new_freq	: out std_logic

	);

	end component;

    -- Signals to hook up the components
	signal test_clk				: std_logic;		
	signal test_n_reset			: std_logic;
	signal test_run_motor		: std_logic;
	signal test_curr_string		: std_logic_vector(2 downto 0);
	signal test_div_quotient	: std_logic_vector(13 downto 0);
	signal test_div_fractional	: std_logic_vector(10 downto 0);
	signal test_new_data		: std_logic;
	signal test_step			: std_logic;
	signal test_dir				: std_logic;
	signal test_tuned			: std_logic;
	signal test_n_stepping		: std_logic;

	signal test_result_div		: std_logic_vector(11 downto 0);
	signal test_result_idx		: std_logic_vector(10 downto 0);
	signal test_sample_done		: std_logic;
	signal test_sample			: std_logic_vector(1 downto 0);

	signal test_disp_wr_en		: std_logic;
	signal test_disp_data		: std_logic_vector(15 downto 0);

	-- type for the string
	type string_freqs is array(0 to 5) of real;
	constant strings : string_freqs := (82.407, 110.000, 146.832, 195.998, 246.942, 329.628);

	-- Variable for the random frequency
	variable string_freq : real;

	signal auto_reset : std_logic;

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

	testAuto : AUTOCORRELATE
		port map(
			clk 			=> test_clk,
			sample 	    	=> test_sample,
			n_reset 		=> auto_n_reset,
			result_div 		=> test_result_div,
			result_idx 		=> test_result_idx,
			done 			=> test_sample_done
		);

	testFrqConv : FREQ_CONVERT
		port map(
			clk 		 	=> test_clk, 		
			divider		 	=> test_result_div,		
			bin			 	=> test_result_idx,			
			sample_done  	=> test_sample_done,
			disp_wr_en	 	=> test_disp_wr_en,
			disp_data	 	=> test_disp_data,	
			quot_out	 	=> test_div_quotient,	
			frac_out	 	=> test_div_fractional,	
			new_freq	 	=> test_new_data	
		);

	-- Wire up the autocorrelation reset. Reset when the stepper motor is stepping
	auto_n_reset <= test_n_reset or test_n_stepping;


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
    -- Send out the samples
    --
    do_samples : process
    	variable time_count : real;
    	variable sin_val	: real;
    begin

    	-- Initialize the time count to 0.
    	time_count := 0;

    	while(END_SIM = FALSE) loop

			-- Calculate the sine.
            sin_val := sin(MATH_2_PI*time_count*string_freq*1000.0);

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
    end process;


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
		variable END_SIM 	: boolean := FALSE;

		variable rand_step_hz, reported_freq 	: real;
		variable sin_val, time_count : real; 
		variable rand 		 	: real;
		variable seed1, seed2 	: positive;

	begin

		-- Initialize everything
		string_idx := 0;
		-- Want to run the motor
		test_run_motor <= '1';

		-- Send the system reset after a clock
		n_reset <= '1';
		wait for 10 ps;
		n_reset <= '0';
		wait for 10 ps;
		n_reset <= '1';

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
			while (test_tuned /= '1') loop

				-- Wait for the autocorrelation unit to finish. When it does finish,
				--	make sure that it detects the frequency correctly.
				while(test_done /= '1') loop
					wait for 10 ps;
				end loop;

				-- Calculate the reported frequency by dividing the input clock (100MHz) by the result divider and index
	            reported_freq  := 100000000.0/(real(to_integer(unsigned(test_result_div)))*real(to_integer(unsigned(test_result_idx))));

	            -- See if we (1) got it right to 1 cent or (2) got a harmonic or (3) failed miserably
	            if ( abs(1.0 - (string_freq/reported_freq)) < 0.001156 ) then
	                assert false report "SUCCESS: Autocorrelation correctly detected to within 2 cents";
	            elsif ( (abs(round(string_freq/reported_freq) - (string_freq/reported_freq)) < 0.01) and (round(string_freq/reported_freq) > 1.5) ) then
	                assert false report "ERROR: Autocorrelation reported harmonic, not actual frequency";
	            else
	                assert false report "ERROR: Autocorrelation incorrectly detected frequency";
	                END_SIM := TRUE;
	            end if;

	            --
	            -- Now, wait for the freq_convert unit to finish
	            --
	            while(new_freq /= '1') loop
	            	wait for 10 ps;
	            end loop;

	           	-- Calculate the reported frequency by dividing the quotient and fractional by 1024
	            reported_freq  := real(to_integer(unsigned(test_div_quotient & test_div_fractional)))/1024.0;

	            -- Make sure that the repoerted frequency is right
	            if ( abs(1.0 - (string_freq/reported_freq)) < 0.001156 ) then
	                assert false report "SUCCESS: Frequency conversion correctly outputted frequency";
	            else
	                assert false report "ERROR: Frequency conversion incorrectly reported frequency";
	                END_SIM := TRUE;
	            end if;

	            --
	            -- Now, wait for the stepping to begin
	            --
	   			while(n_stepping /= '0') loop
	   				wait for 10 ps;
	   			end loop;

	   			-- Once the stepping has begun, adjust the sample frequency 
	   			--	after each step
	   			while(n_stepping = '0') loop
	   				if (test_step = '1') then
	   					if (test_dir = '1') then
	   						string_freq := string_freq + 1/rand_step_hz;
	   					else
	   						string_freq := string_freq - 1/rand_steps_hs;
	   					end if;

	   					while(test_step = '1') loop
	   						wait for 10 ps;
	   					end loop;
	   				else
	   					wait for 10 ps;
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
            wait for 10 ps;

        end loop;

    end process;

end architecture;






