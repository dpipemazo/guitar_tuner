--
-- Stepper Motor Controller Unit
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

-- The actual entity
entity STEPPERCONTROL is 
    port(

        -- clocks
        clk        : in std_logic;
        step_clk   : in std_logic;

        -- output to the stepper motor
        step    : out std_logic;
        dir     : out std_logic;
        enable  : out std_logic; -- active low

        -- Input switch telling which direction to turn motor
        dir_switch : in std_logic;

        --
        -- DATA. DO NOT CHANGE THESE
        --  WHILE WAITING FOR THE SYSTEM
        --  TO RUN. IT WILL BREAK EVERYTHING
        --
        -- Detected Frequency in Q9.4
        freq_detected : in std_logic_vector(12 downto 0);
        -- String to tune
        string_num : in std_logic_vector(2 downto 0);

        -- Control signals
        run_motor   : in std_logic;
        motor_done  : out std_logic;
        tuned       : out std_logic
    );
end STEPPERCONTROL;

-- The architecture
architecture behavioral of STEPPERCONTROL is
    -- the stepper divider
    component stepper_divider
        port (
            clk: in std_logic;
            nd: in std_logic;
            rdy: out std_logic;
            rfd: out std_logic;
            dividend: in std_logic_vector(12 downto 0);
            divisor: in std_logic_vector(12 downto 0);
            quotient: out std_logic_vector(12 downto 0);
            fractional: out std_logic_vector(12 downto 0)
        );
    end component;

    -- states for the stepper motor state machine
    type step_states is(
        STEP_IDLE, 
        SEND_STEPS_HIGH,
        SEND_STEPS_LOW
    );
    signal step_state : step_states;

    -- states for the main state machine
    type step_ctrl_states is(
        IDLE, 
        CHECK_TUNED, 
        GET_STEP_CONSTANT, 
        DO_DIVIDE, 
        CALC_MULTIPLIER,
        CALC_STEP_MULTIPLIER,
        CALC_STEPS, 
        WAIT_STEPS,
        UNTUNED_FINISH,
        TUNED_FINISH
    );
    signal curr_state : step_ctrl_states;

    -- How many steps/Hz we should use to multiply
    signal step_multiplier : std_logic_vector(11 downto 0);

    -- Expected frequency
    signal expected : std_logic_vector(12 downto 0);

    -- Results based on expected frequencies
    signal freq_diff : std_logic_vector(12 downto 0);
    signal abs_freq_diff : std_logic_vector(12 downto 0);

    -- Divider signals
    signal fractional : std_logic_vector(12 downto 0);
    signal div_rdy : std_logic;
    signal div_new_data : std_logic;

    -- Frequency difference at which we call it tuned, currently anything less
    --  than 1 Hz of difference is good.
    constant cutoff_freq_diff : std_logic_vector(12 downto 0) := "0000000001111";

    -- Whether we attempted to increase/decrease the frequency last time
    signal last_attempt : std_logic;
    -- signal to determine if we are on our first attempt or not
    signal first_attempt : std_logic;

    -- Signals for number of steps to take
    signal num_steps : std_logic_vector(9 downto 0);
    signal step_counter : std_logic_vector(9 downto 0);
    signal do_steps : std_logic;
    signal steps_done : std_logic;

    -- signal to figure out what the step multiplier change was, in form Q1.12
    signal step_multiplier_change : std_logic_vector(13 downto 0);


begin

    -- 
    -- Get the expected frequency, in Q9.4
    --
    expected <= "0010100100111" when (string_num = "000") else --  82.4375 for the E2 string
                "0011011100000" when (string_num = "001") else -- 110.0000 for the A string
                "0100100101101" when (string_num = "010") else -- 146.8125 for the D string
                "0110001000000" when (string_num = "011") else -- 196.0000 for the G string
                "0111101101111" when (string_num = "100") else -- 246.9375 for the B string
                "1010010011010" when (string_num = "101") else -- 329.6250 for the E4 string
                (others => '0');

    --
    -- Calculate the difference between the expected and observed frequencies
    --
    freq_diff <= expected - freq_detected;

    --
    -- Absolute value of the frequency difference
    --
    abs_freq_diff <= freq_diff               when (freq_diff(12) = '0') else
                     (not freq_diff) + 1;

    --
    -- Set up the divider, only care about the fractional
    --
    stpdiv : stepper_divider
        port map (
            clk => clk,
            rdy => div_rdy,
            nd  => div_new_data,
            dividend => abs_freq_diff,
            divisor => expected,
            fractional => fractional
        );

    --
    -- Make the main state machine based off of the normal clock
    --
    process(clk)
        variable multiply_result  : std_logic_vector(25 downto 0);
        variable num_steps_result : std_logic_vector(24 downto 0);
    begin

        if (rising_edge(clk)) then

            case curr_state is 

                --
                -- Sit here, waiting for a run command. When the run command is sent, 
                -- go to check to see if we are tuned. Else, wait in the IDLE state
                --
                when IDLE =>

                    motor_done <= '0';
                    tuned <= '0';

                    if (run_motor = '1') then
                        curr_state <= CHECK_TUNED;
                    else
                        curr_state <= IDLE;
                    end if;

                --
                -- Calculate the frequency difference and check to see if we are 
                --  indeed tuned
                --
                when CHECK_TUNED =>

                    -- If the frequency is less than the cutoff, call it good
                    if (freq_diff < cutoff_freq_diff) then
                        curr_state <= TUNED_FINISH;
                    else
                        curr_state <= GET_STEP_CONSTANT;
                    end if;

                --
                -- We need to figure out our constant for how many steps/Hz 
                --  should be taken. If this is the first time which we are
                --  here, then we just use the precalculated one, else
                --  we need to give some feedback and adjust it.
                --
                when GET_STEP_CONSTANT =>  

                    -- If this is our first attmept at tuning, just use the
                    --  precalculated constant
                    if (first_attempt = '1') then
                        
                        --
                        -- Assign the string multiplier based on the current 
                        --  value of string_num, in Q8.4
                        --
                        case string_num is
                            when "000" =>
                                step_multiplier <= "000111001001"; -- 28.5625 steps/Hz for the E2 string
                            when "001" =>
                                step_multiplier <= "001001100001"; -- 38.0625 steps/Hz for the A string
                            when "010" =>
                                step_multiplier <= "001010000000"; -- 40.0000 steps/Hz for the D string
                            when "011" =>
                                step_multiplier <= "001011000111"; -- 44.4375 steps/Hz for the B string
                            when "100" =>
                                step_multiplier <= "000111001001"; -- 28.5625 steps/Hz for the G string
                            when "101" =>
                                step_multiplier <= "001000010101"; -- 33.3125 steos/Hz for the E4 string
                            when others =>
                                step_multiplier <= (others => '0');
                        end case;

                        curr_state <= CALC_STEPS;

                    -- Otherwise, we need to calculate our new step constant, 
                    -- which first needs a divide.
                    else
                        curr_state <= DO_DIVIDE;

                        -- tell the divider to run
                        div_new_data <= '1';
                    end if;

                --
                -- Perform the divide of abs_freq_diff/expected_freq to figure out
                --  how far off we were so that we can adjust our constant accodringly.
                --
                when DO_DIVIDE =>

                    -- clear the divider new data signal
                    div_new_data <= '0';

                    -- Wait until the divider is done
                    if (div_rdy = '1') then
                        curr_state <= CALC_MULTIPLIER;
                    else
                        curr_state <= DO_DIVIDE;
                    end if;

                --
                -- Now that we have abs_freq_diff/expected_freq, we need to 
                --  figure out whether to increase the step multiplier by
                --  the desired percent or decrease it by the calculated percent.
                -- 
                -- Here is the truth table:
                --
                --                  Sign bit of freq_diff
                --  Last attempt
                --                  |   0   |   1
                --           ------------------------
                --              0   |   0   |   1
                --           -------|-------|--------
                --              1   |   1   |   0
                --           ------------------------
                --
                --  If we were attempting to decrease it last time, (last_attempt = 0), 
                --  and we have a negative difference (actual > expected), then we didn't
                --  decrease it by enough and we need to INCREASE the constant. Similarly, 
                --  if we were attempting to increase it but we have a positive difference 
                --  (actual < expected) we also need to INCREASE the constant. The converse
                --  holds for this as well. Use an XOR to determine increasing/decreasing
                --  the constant.
                --
                when CALC_MULTIPLIER =>
                    
                    -- NOTE: freq_change_multiplier will be in form
                    -- Q1.13;
                    if ((freq_diff(12) xor last_attempt) = '1') then
                        step_multiplier_change <= '1' & fractional;
                    else
                        step_multiplier_change <= ('0' & (not fractional)) + 1;
                    end if;

                    curr_state <= CALC_STEP_MULTIPLIER;

                --
                -- Now, need to calculate the new step multiplier
                --
                --  Do this by multiplying the old multiplier by the 
                --  change and then rounding/chopping the answer to the
                --  form which we want/expect
                --
                when CALC_STEP_MULTIPLIER =>

                    -- Get our new multiplier using the constant which
                    --  is computed asynchronously for now, and then
                    --  go on to figure out how many steps to take
                    -- Step_multiplier is Q8.4, and step_multiplier_change is Q1.13, so multiply_result
                    --  will be Q9.17
                    multiply_result := step_multiplier * step_multiplier_change;

                    -- Take the Q8.4 result out of the multiply result;
                    step_multiplier <= multiply_result(24 downto 13);

                    curr_state <= CALC_STEPS;

                --
                -- Now that we've integrated our feedback and figured out the
                --  new step multiplier, we need to actually calculate how many
                --  steps we need to take.
                --
                when CALC_STEPS =>

                    -- Step_multiplier is in form Q8.4, and freq_difference is
                    --  in form Q9.4, so our result will be of the form Q17.8
                    num_steps_result := abs_freq_diff * step_multiplier;
                    -- round down to the closest step, 10 bits worth of steps should
                    -- be enough
                    num_steps <= num_steps_result(17 downto 8);
                    
                    --
                    -- Set the direction for the stepper motor as well. If 
                    -- the high bit of the frequency difference is set, then we need to decrease the
                    -- frequency, since the observed > expected. Use the directional switch to 
                    -- control which way to turn the knob, since it varies based on which
                    -- side of the headstock the switch is on.
                    --
                    if ((freq_diff(12) xor dir_switch) = '1') then
                        dir <= '1';
                    else
                        dir <= '0';
                    end if;

                    -- Tell the stepper controller to go
                    do_steps <= '1';
                    -- and wait for it to finish
                    curr_state <= WAIT_STEPS;

                -- Wait for the steps to be sent at 500KHz
                when WAIT_STEPS =>

                    -- If the stepper controller says that it's done, 
                    -- then finish
                    if (steps_done = '1') then
                        do_steps <= '0';
                        curr_state <= UNTUNED_FINISH;

                    -- Otherwise, wait here for it to finish
                    else
                        curr_state <= WAIT_STEPS;
                    end if;


                when UNTUNED_FINISH =>

                    -- note that we are no longer in our first attempt
                    first_attempt <= '0';
                    -- note that we tried to increase/decrease the gain on
                    -- our last_attempt
                    last_attempt <= not freq_diff(12);

                    -- set the done flag high
                    motor_done <= '1';

                    -- and return back to IDLE
                    curr_state <= IDLE;


                when TUNED_FINISH =>

                    -- Now we're back on our first attempt, yay!
                    first_attempt <= '1';

                    -- Set the done flag high
                    motor_done <= '1';

                    -- Set the tuned flag high
                    tuned <= '1';

                    -- And return back to IDLE;
                    curr_state <= IDLE;

                when others =>
                    curr_state <= IDLE;

            end case;

        end if;

    end process;

    --
    -- State machine for sending the steps based off of the step
    --  clock which needs to be running close to but less than
    --  500 khz
    --
    process(step_clk)
    begin

        if (rising_edge(step_clk)) then

            case step_state is

                -- Waiting for the command to start sending steps
                when STEP_IDLE =>

                    step <= '0';
                    enable <= '1';
                    steps_done <= '0';
                    step_counter <= (others => '0');

                    if (do_steps = '1') then
                        step_state <= SEND_STEPS_LOW;
                    else
                        step_state <= STEP_IDLE;
                    end if;

                -- Send the step clock low
                when SEND_STEPS_LOW =>

                    step <= '0';
                    step_state <= SEND_STEPS_HIGH;

                -- Send the step clock high and check to see if
                --  we are done
                when SEND_STEPS_HIGH =>
                     step <= '1';

                     if (conv_integer(step_counter) = (conv_integer(num_steps) - 1)) then
                        step_state <= STEP_IDLE;
                        steps_done <= '1';
                    else
                        step_counter <= step_counter + 1;
                        step_state <= SEND_STEPS_LOW;
                    end if;

            end case;

        end if;

    end process;

end architecture;
                    













