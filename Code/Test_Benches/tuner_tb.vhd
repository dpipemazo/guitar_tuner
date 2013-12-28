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

begin

	--
	-- Need to wire up the units under test
	--
	testTuner : TUNER
		port map(
			clk				=> test_clk.
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
			n_reset 		=> test_n_reset,
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
	






	