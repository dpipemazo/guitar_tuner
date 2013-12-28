--
-- This is the file which controls the stepper motor.
--	and evaluates if the incoing frequency is indeed in
--	tune.
--	
--	This file will take the following inputs
--		1. Detected frequency : Q14.10
--		2. Current String
--		3. A signal to run the motor or not
--
--	This file will have the following outputs
--		1. Stepper motor step command
--		2. Tuned signal when frequency is within threshold
--

--
-- Libraries
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work;
use work.freq_constants.all;
use work.steps_hz_divider;

entity TUNER is

	port(
		-- System clock and reset
		clk				: in std_logic; -- system clock
		n_reset			: in std_logic;

		-- Signals from the UI unit
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

		-- Whether or not the frequency is in tune. Will pulse high for 
		--	one system clock
		tuned			: out std_logic;
		-- Whether or not the unit is in the process of sending steps
		--	active low when in the process of stepping. 
		n_stepping		: out std_logic

	);

end TUNER;


--
-- The architecture
--
architecture behavioral of TUNER is
	
	-- High and low thresholds for being in tune. These
	--	will be set to the expected frequency +/- 
	--	a certain number of cents' worth of error.
	signal high_threshold : std_logic_vector(24 downto 0);
	signal low_threshold  : std_logic_vector(24 downto 0);

	-- Signal for the expected frequency, since it's a 
	--	hassle to write all of the time
	signal expected_freq 	: std_logic_vector(23 downto 0);

	-- Put the input frequency together
	signal new_freq		: std_logic_vector(23 downto 0);
	signal old_freq		: std_logic_vector(23 downto 0);

	-- Range 0-255. Used as a wait counter in the state machine in order
	--	to dilute the system clock down to a level that
	--	is acceptable for the stpper chip.
	signal step_wait_counter : std_logic_vector(7 downto 0);

	-- The number of steps to take, multiplied by 1024
	signal new_steps_x_1024 	: std_logic_vector(22 downto 0);
	signal step_multiplier		: std_logic_vector(12 downto 0);
	signal new_steps_mux		: std_logic_vector(9 downto 0);
	signal new_steps			: std_logic_vector(9 downto 0);
	signal old_steps			: std_logic_vector(9 downto 0);
	signal abs_steps			: std_logic_vector(9 downto 0);

	--
	-- Signals for the differences
	--
	signal freq_to_go		: std_logic_vector(24 downto 0);
	signal freq_moved		: std_logic_vector(24 downto 0);

	--
	-- Signals for the divider
	--
	signal dividend			: std_logic_vector(17 downto 0);
	signal divisor			: std_logic_vector(17 downto 0);
	signal quotient			: std_logic_vector(17 downto 0);
	signal fractional 		: std_logic_vector(9 downto 0);
	signal divide_rdy		: std_logic;
	signal divide_rfd 		: std_logic;
	signal divide_nd		: std_logic;
	signal divide_nd_sig 	: std_logic;

	--
	-- Latch the quotient and fractional after divide
	--
	signal latched_quotient			: std_logic_vector(17 downto 0);
	signal latched_fractional 		: std_logic_vector(9 downto 0);

	-- Signals for the stepper controller to know
	--	to send steps
	signal num_steps		: std_logic_vector(8 downto 0);

	--
	-- Reset values for old_steps and old_freq
	--
	constant steps_reset_val 	: std_logic_vector(9 downto 0) := "0000010000";
	constant freq_reset_val 	: std_logic_vector(23 downto 0) := "000000000000000000000000";

	-- Signal telling that it's the first run of the algorithm
	signal first_run 			: std_logic;

	-- Latch for the old current string to see if we got a nw current string
	signal curr_string_latch : std_logic_vector(2 downto 0);

	--
	-- States for the tuning state machine
	--
	type tune_states is (
		IDLE,
		CHECK_TUNED, 
		DO_DIVIDE, 
		GET_NEW_STEPS, 
		SEND_STEPS_PREP,
		SEND_STEPS_HIGH,
		SEND_STEPS_LOW			
	);

	signal curr_state : tune_states;

begin

	--
	---
	---- GETTING THE EXPECTED FREQUENCY
	---
	--

	--
	-- Get the expected frequency based off of the current 
	--	string. The current string is 0 when in free
	--	tune mode. So account for that
	--
	expected_freq <= 	expected_freqs(to_integer(unsigned(curr_string) - 1)) when not std_match(curr_string, "000") else
						(others => '0');

	--
	---
	---- LOGIC FOR FIGURING OUT THE NEW NUMBER OF STEPS
	---
	--

	divide_nd_sig <= divide_nd and n_reset;
	stepHzDiv: entity STEPS_HZ_DIVIDER
		port map(
			rfd 		=> divide_rfd,
			rdy 		=> divide_rdy,
			nd 			=> divide_nd_sig, 
			clk 		=> clk,
			dividend 	=> dividend,
			quotient 	=> quotient,
			divisor 	=> divisor,
			fractional 	=> fractional
		);

	-- Calculate freq_to_go and freq_moved
	freq_to_go <= std_logic_vector(("0" & signed(expected_freq)) 	- ("0" & signed(new_freq)));
	freq_moved <= std_logic_vector(("0" & signed(new_freq)) 		- ("0" & signed(old_freq)));

	--
	-- The inputs to the divider are freq_to_go and freq_moved. We cap these
	--	values at +/- 127 in Q7.10 form, so need to add that logic in. 
	--
	dividend 	<= "011111110000000000" when (signed(freq_to_go(24 downto 10)) >= 128) else
				   "100000010000000000" when (signed(freq_to_go(24 downto 10)) <= -127) else
				   freq_to_go(17 downto 0);

	divisor 	<= "011111110000000000" when (signed(freq_moved(24 downto 10)) >= 128) else
				   "100000010000000000" when (signed(freq_moved(24 downto 10)) <= -127) else
				   freq_moved(17 downto 0);
	--
	-- The quotient will be limited to +/- 2 plus fractional. When the algorithm starts, 
	--	the number of steps taken will be small, and this value will most likely 
	--	go to +/- 2. As the algorithm runs, though, the number of steps will
	--	converge to the correct value without overshooting.
	--
	step_multiplier	 	<= 	"0100000000000" when (signed(latched_quotient) >= 2) else
							"1100000000000" when (signed(latched_quotient) <= -2) else
							latched_quotient(2 downto 0) & latched_fractional;

	--
	-- Now calculate the number of steps by multiplying the step
	--	multiplier by the past number of steps and then truncating
	--	the low 10 bits 
	--
	new_steps_x_1024 	<= std_logic_vector(signed(old_steps) * signed(step_multiplier));
	--
	-- We are multiplying the old steps value by 2, so we need
	--	to threshold it at the max and min of +/- 511
	--
	new_steps_mux 		<=  "1000000001" when ( signed(new_steps_x_1024(22 downto 10)) <= -512 ) else
							"0111111111" when ( signed(new_steps_x_1024(22 downto 10)) >= 512 ) else
							new_steps_x_1024(19 downto 10);

	--
	-- Need to take into account that the sign of steps will
	--	tell which direction relative to the current direction
	--	the motor should be turned.
	--
	abs_steps			<= 	std_logic_vector(unsigned(not new_steps) + 1) when (new_steps(9) = '1') else
							new_steps;


	--
	---
	---- CALCULATING THE THRESHOLDS OF BEING IN TUNE
	---
	--

	-- We need to figure out the thresholds. Initially, set the
	--	error to a bit under 5 cents by calculating the 
	--	expected frequency +/- the expected frequency/12. 
	high_threshold 	<= std_logic_vector("0000000000" & unsigned(expected_freq(23 downto 9)));
	low_threshold 	<= std_logic_vector(unsigned(not high_threshold) + 1);


	stepClk : process(clk)
	begin

		if (rising_edge(clk)) then

			--
			-- Need to monitor if we are changing strings. If so, 
			--	act as if it were a reset
			--
			curr_string_latch <= curr_string;

			--
			-- If we get a reset signal or the current string changes or we shouldn't 
			--	be running the stepper motor
			--
			if ( (n_reset = '0') or (not std_match(curr_string, curr_string_latch)) or (run_motor = '0') or std_match(curr_string, "000") ) then
				step_wait_counter 	<= (others => '0');
				curr_state 			<= IDLE;
				first_run			<= '1';
				tuned				<= '0';
				n_stepping 			<= '1';
				new_freq			<= (others => '0');
				old_freq 			<= (others => '0');
				divide_nd 			<= '0';
			else

				--
				-- Run the state machine which controls the tuning
				--
				case curr_state is 

					--
					-- We are waiting for a new reading from the autocorrelation unit
					--
					when IDLE =>

						--
						-- Always send tuned back low in idle
						--
						tuned <= '0';
						divide_nd <= '0';
						n_stepping <= '1';

						-- If we get a new reading, then move on to
						--	check the thresholds.
						if (new_data = '1') then
							-- The new frequency is always the new reading
							new_freq 	<= div_quotient & div_fractional;
							old_freq	<= new_freq;
							curr_state 	<= CHECK_TUNED;
						else
							curr_state <= IDLE;
						end if;

					--
					-- We want to check and see if the current frequency is 
					--	within the thresholds
					--
					when CHECK_TUNED =>
						-- Need to send the divide new data signal low
						divide_nd <= '0';

						-- See if the difference between the input frequency and expected is between the thresholds
						if ((signed(freq_to_go) < signed(high_threshold)) and (signed(freq_to_go) > signed(low_threshold))) then
							tuned 		<= '1';
							first_run 	<= '1';
							curr_state 	<= IDLE;
						else
							-- If this is our first run, then there's no point in
							--	doing the divide since the data is bad. So skip it
							if (first_run = '1') then
								curr_state <= GET_NEW_STEPS;
							else
								divide_nd 	<= '1';
								curr_state 	<= DO_DIVIDE;
							end if;
						end if;



					--
					-- We are not tuned, so calculate the ratio of the 
					--	frequency to go versus the frequency moved
					--
					when DO_DIVIDE =>
						-- Wait for the divide data to be ready. If it is,
						--	then we need to latch the data because it is 
						--	only valid for one cycle.
						divide_nd <= '0';

						if (divide_rdy = '1') then
							latched_quotient 	<= quotient;
							latched_fractional 	<= fractional;
							curr_state 		<= GET_NEW_STEPS;
						else
							curr_state 		<= DO_DIVIDE;
						end if;


					--
					-- We need to latch the new number of steps to take
					--	as well as update the old number of steps
					--
					when GET_NEW_STEPS => 

						-- Need to be careful if this is the 
						--	first run. If it's the first run, then
						--	we don't have the data necessary so 
						--	just make up the step values
						if (first_run = '1') then
							new_steps <= steps_reset_val;
						else
							-- Latch the step values
							new_steps <= new_steps_mux;
						end if;

						-- Move onto sending the new steps
						curr_state <= SEND_STEPS_PREP;

					--
					-- Need to get ready to send the steps
					--
					when SEND_STEPS_PREP =>

						-- Need to update the 'old' steps for next time.
						old_steps <= new_steps;

						-- Always send the stepper motor
						--	in the direction of the
						--	steps
						dir <= new_steps(9);

						-- Latch the number of steps which need
						--	to be taken.
						num_steps <= abs_steps(8 downto 0);

						-- Need to initialize the step wait counter to 0
						step_wait_counter <= (others => '0');

						-- Indicate that we are stepping
						n_stepping <= '0';

						curr_state <= SEND_STEPS_HIGH;

					--
					-- Send the first half of the step
					--
					when SEND_STEPS_HIGH =>

						-- Send the step
						step <= '1';

						-- Increment the counter
						step_wait_counter <= std_logic_vector(unsigned(step_wait_counter) + 1);

						-- If the counter is at a max, then move onto the low portion of the step
						if (unsigned(step_wait_counter) = 255) then
							curr_state <= SEND_STEPS_LOW;
						else
							curr_state <= SEND_STEPS_HIGH;
						end if;

					--
					-- Send the second half of the step
					--
					when SEND_STEPS_LOW =>

						-- Send step back low
						step <= '0';

						-- Increment the counter
						step_wait_counter <= std_logic_vector(unsigned(step_wait_counter) + 1);

						-- If the counter is at a max, move onto the high portion of the
						--	step unless we are done.
						if (unsigned(step_wait_counter) = 255) then

							-- If we just sent the last step
							if (unsigned(num_steps) = 1) then
								-- Reset the first_run signal
								first_run 	<= '0';
								-- And go back to idle
								curr_state 	<= IDLE;

							-- Otherwise decrement the number of steps to go and 
							--	go back to the high part
							else
								curr_state 	<= SEND_STEPS_HIGH;
								num_steps 	<= std_logic_vector(unsigned(num_steps) - 1);
							end if;

						else
							curr_state <= SEND_STEPS_LOW;
						end if;

					--
					-- In case something goes wrong
					--
					when others =>
						curr_state <= IDLE;
				
				end case;

			end if;

		end if;

	end process;

end architecture;

















