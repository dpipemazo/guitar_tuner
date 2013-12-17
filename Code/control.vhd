----------------------------------------------------------------------------
--
-- Control Unit for Digital Pitch Detector
--
--
-- This control unit performs the following tasks:
--  1. Handles user input
--  2. Handles the display
--  3. Sends contol signals to the system
--
-- It is essentially a big state machine
----------------------------------------------------------------------------

-- Import the standard IEEE libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.display_constants.all;

entity  CONTROL  is

    port(

        -- system clock
        clk         : in std_logic;
        -- debouncing clock
        debounce_clk  : in std_logic;

        -- pushbuttons
        btn         : in std_logic_vector(5 downto 0);

        -- signals to/from the sampling unit
        sample_start    : out std_logic;
        sample_done     : in std_logic;

        -- signals to/from the bcd conversion unit
        bcd_conv_start  : out std_logic;
        bcd_conv_done   : in std_logic;

        -- copntrol signals to/from the display unit
        display_line_start  : out std_logic;
        display_char_start  : out std_logic;
        display_reset_start : out std_logic;
        display_done        : in std_logic;
        display_ack         : in std_logic;

        -- Data to/from the display unit
        display_data    : out std_logic_vector(7 downto 0);
        line_to_update  : out std_logic_vector(1 downto 0);
        char_to_update  : out std_logic_vector(4 downto 0);

        -- BCD frequency detected
        bcd_freq        : in std_logic_vector(51 downto 0);

        -- string which we are working on
        string_num      : out std_logic_vector(2 downto 0);

        -- auto tuning signals
        auto_start      : out std_logic;
        auto_done       : in std_logic; 
        tuned           : in std_logic

    );

end  CONTROL;

architecture behavioral of CONTROL is

    type control_states is(
        IDLE,
        BUTTON_DECODE,
        DISPLAY_RESET,
        UI_INIT,
        DISPLAY_WAIT,
        DISPLAY_UPDATE_LINE_1,
        DISPLAY_UPDATE_LINE_2,
        DISPLAY_UPDATE_LINE_3,
        DISPLAY_UPDATE_LINE_4,
        TURN_ON_AUTO,
        TURN_OFF_AUTO,
        STRING_DOWN,
        STRING_UP,
        RUN_SAMPLING,
        CONV_FREQ_BCD_INIT,
        CONV_FREQ_BCD_WAIT,
        DISPLAY_FREQ_TEMPLATE,
        DISPLAY_FREQ_INTEGER,
        DISPLAY_FREQ_DECIMAL,
        DO_AUTO_TUNE, 
        AUTO_TUNE_WAIT
    );
    signal curr_state : control_states;
    signal next_state : control_states;

    -- counter for debouncing, sitcks when full
    signal debounce_counter : std_logic_vector(10 downto 0);

    -- Synchronization for switches and buttons
    signal button_sync_1 : std_logic_vector(5 downto 0);
    signal button_sync_2 : std_logic_vector(5 downto 0);
    signal button_down_1 : std_logic;
    signal button_down_2 : std_logic;
    signal button_down_rising_edge : std_logic;
    signal button_pressed : std_logic;

    -- control constants
    signal guitar_string_num : std_logic_vector(2 downto 0); -- which guitar string we are tuning
    signal auto_tune : std_logic; -- whether or not to do auto-tuning. 

    -- Frequency display constants
    signal frq_counter : std_logic_vector(3 downto 0); 
    signal got_nonzero : std_logic;

    -- Display wait signals
    signal got_ack : std_logic;
    signal auto_got_ack : std_logic;

    -- signal to make char_to_update an output
    signal display_char : std_logic_vector(4 downto 0);

begin

    --
    -- Map display_char directly to char_to_update
    --
    char_to_update <= display_char;
    string_num <= guitar_string_num;

    --
    -- Debounce buttons coming in
    --
    process(debounce_clk)
    begin

        if (rising_edge(debounce_clk)) then

            -- synchronize the button coming in. 
            button_sync_1 <= btn(5 downto 0);
            button_sync_2 <= button_sync_1;

            -- keep a history on button_down;
            button_down_2 <= button_down_1;

            -- If we are in the process of debouncing a button press.
            if (button_pressed = '1') then
                if (AND_REDUCE(debounce_counter) = '0') then
                    debounce_counter <= debounce_counter + 1;
                -- If we have debounced a button press
                else
                    button_down_1 <= '1';
                end if;
            -- No button is being pressed.
            else
                debounce_counter <= (others => '0');
                button_down_1 <= '0';
            end if;

        end if;
    end process;

    --
    -- Logic to handle button recognition. XOR buttons with
    --  all ones, and then OR-reduce the result
    button_pressed <= OR_REDUCE(button_sync_2(5 downto 1)) or not button_sync_2(0);

    -- 
    -- Logic to find a rising ege on button_down
    --
    button_down_rising_edge <= button_down_1 and not button_down_2;

    --
    -- The General control loop. 
    -- Can be run at standard clock speeds, since the display loop will be
    --  run at slowed clock speeds
    --
    process(clk)

        -- Variables
        variable frq_digit : std_logic_vector(3 downto 0);

    begin

        if (rising_edge(clk)) then

            --
            -- RESET
            --
            if ((button_down_rising_edge = '1') and (button_sync_2(0) = '0')) then

                curr_state <= DISPLAY_RESET;

            --
            -- NOT RESET
            --
            else

                case curr_state is 

                    --
                    -- IDLE state: wait for a button to be pressed
                    --
                    when IDLE =>

                        -- Clear the got_ack signal from the display
                        got_ack <= '0';

                        -- If a button is pressed
                        if (button_down_rising_edge = '1') then
                            curr_state <= BUTTON_DECODE;
                        -- No button was pressed
                        else
                            curr_state <= IDLE;
                        end if;

                    --
                    -- A button has been pressed, so figure out which
                    --  one and react accordingly
                    --
                    when BUTTON_DECODE =>
                        -- If the up button is pressed
                        if (button_sync_2(1) = '1') then 
                            curr_state <= TURN_ON_AUTO;
                        end if;

                        -- If the left button is pressed
                        if (button_sync_2(2) = '1') then
                            curr_state <= STRING_DOWN;
                        end if;

                        -- If the down button is pressed
                        if (button_sync_2(3) = '1') then
                            curr_state <= TURN_OFF_AUTO;
                        end if;

                        -- If the right button is pressed
                        if (button_sync_2(4) = '1') then
                            curr_state <= STRING_UP;
                        end if;

                        -- If the center button is pressed
                        if (button_sync_2(5) = '1') then
                            sample_start <= '1';
                            curr_state <= RUN_SAMPLING;
                        end if;

                    --
                    -- We got a reset press, so reset the display and some local variables, 
                    -- and then put the UI back on the display
                    --
                    when DISPLAY_RESET => 
                        
                        display_reset_start <= '1';
                        curr_state <= DISPLAY_WAIT;
                        -- Re-write the first line of the display
                        next_state <= UI_INIT;

                    when UI_INIT =>
                        -- Set the string which we are looking to tune to 0
                        guitar_string_num <= (others => '0');
                        -- Turn off auto tuning
                        auto_tune <= '0';
                        -- Reset the display
                        curr_state <= DISPLAY_WAIT;
                        next_state <= IDLE;

                    --
                    -- DISPLAY CONTROLLER
                    -- STATES
                    --

                    -- Wait for the display controller to tell us 
                    --  that it's done
                    when DISPLAY_WAIT =>
                        -- Reset all of the display controls if the
                        --  display has acknowledged the command
                        if (display_ack = '1') then
                            display_reset_start <= '0';
                            display_line_start <= '0';
                            display_char_start <= '0';
                            got_ack <= '1';
                        end if;

                        if (display_done = '1' and got_ack = '1') then
                            curr_state <= next_state;
                            got_ack <= '0';
                        else
                            curr_state <= DISPLAY_WAIT;
                        end if;

                    -- Update the 1st line of the display
                    when DISPLAY_UPDATE_LINE_1 =>
                        -- Update the first line of the display
                        line_to_update <= "00";
                        -- Update the line with the proper string
                        display_data <= "0000" & guitar_string_num & auto_tune;
                        -- Tell the display to begin the line update
                        display_line_start <= '1';
                        -- Wait for the display to finish and then go to IDLE.
                        curr_state <= DISPLAY_WAIT;

                    -- Update the 2nd line of the display
                    when DISPLAY_UPDATE_LINE_2 =>
                        line_to_update <= "01";
                        display_data <= (others => '0');
                        display_line_start <= '1';
                        curr_state <= DISPLAY_WAIT;

                    -- Update the 3rd line of the display
                    when DISPLAY_UPDATE_LINE_3 =>
                        line_to_update <= "10";
                        display_data <= (others => '0');
                        display_line_start <= '1';
                        curr_state <= DISPLAY_WAIT;

                    -- Update the 4th line of the display
                    when DISPLAY_UPDATE_LINE_4 =>
                        line_to_update <= "11";
                        display_data <= (others => '0');
                        display_line_start <= '1';
                        curr_state <= DISPLAY_WAIT;


                    --
                    -- Turn on Automatic tuning and then update the top line
                    -- of the display
                    --
                    when TURN_ON_AUTO =>
                        -- Turn on the auto-tune feature
                        auto_tune <= '1';
                        curr_state <= DISPLAY_UPDATE_LINE_1;

                    --
                    -- Turn off automatic tuning and then update the top line 
                    --  of the display
                    --
                    when TURN_OFF_AUTO =>
                        auto_tune <= '0';
                        curr_state <= DISPLAY_UPDATE_LINE_1;

                    --
                    -- Change the string being tuned by one string "down" on the guitar
                    --  and then update the top line of the display
                    --
                    when STRING_DOWN =>
                        if (OR_REDUCE(guitar_string_num) = '0') then
                            guitar_string_num <= "101";
                        else
                            guitar_string_num <= guitar_string_num - 1;
                        end if;

                        curr_state <= DISPLAY_UPDATE_LINE_1;

                    --
                    -- Change the string being tuned by one string "up" on the 
                    --  guitar and then update the top line of the display
                    --
                    when STRING_UP =>
                        if (guitar_string_num = "101") then
                            guitar_string_num <= "000";
                        else
                            guitar_string_num <= guitar_string_num + 1;
                        end if;

                        curr_state <= DISPLAY_UPDATE_LINE_1;

                    --
                    -- Begin the process of pitch detection by starting the
                    --  sampling loop and waiting for it to complete
                    --
                    when RUN_SAMPLING =>
                        sample_start <= '0';
                        if (sample_done = '1') then
                            curr_state <= CONV_FREQ_BCD_INIT;
                        else
                            curr_state <= RUN_SAMPLING;
                        end if;

                    --
                    -- Convert the frequency which we got from the 
                    --  sampling to BCD
                    --
                    when CONV_FREQ_BCD_INIT => 

                        bcd_conv_start <= '1';

                        curr_state <= CONV_FREQ_BCD_WAIT;

                    when CONV_FREQ_BCD_WAIT =>

                        bcd_conv_start <= '0';

                        if (bcd_conv_done = '1') then
                            curr_state <= DISPLAY_FREQ_TEMPLATE;
                        else
                            curr_state <= CONV_FREQ_BCD_WAIT;
                        end if; 

                    -- Update the 3rd line of the display with the correct
                    --  frequency
                    when DISPLAY_FREQ_TEMPLATE =>
                        -- Update the 3rd line with the frequency template
                        curr_state <= DISPLAY_UPDATE_LINE_3;
                        next_state <= DISPLAY_FREQ_INTEGER;
                        
                        -- Set signals for the frequency update
                        frq_counter <= "1000";
                        display_char <= "00101";
                        got_nonzero <= '0';

                    --
                    -- Do not display leading zeroes, but display
                    --  the integer portion of the frequency
                    --
                    when DISPLAY_FREQ_INTEGER =>

                        -- make the high bits of the display data equal to 0x3 so that
                        --  we can just tack the integer onto the end to make an ASCII-encoded
                        --  integer
                        display_data(7 downto 4) <= "0011";

                        -- Get the current frequency digit
                        frq_digit := bcd_freq((4*conv_integer(frq_counter) + 19) downto (4*conv_integer(frq_counter) + 16));

                        -- Always put the freq digit on the display lines
                        display_data(3 downto 0) <= frq_digit;

                        -- If we are looking for the first nonzero digit and we're not on the last digit
                        if (got_nonzero = '0' and OR_REDUCE(frq_counter) = '1') then

                            -- Update the display char and frq_counter variables
                            frq_counter <= frq_counter - 1;
                            display_char <= display_char + 1;

                            -- Figure out if we should show or skip the digit
                            if (OR_REDUCE(frq_digit) = '1') then
                                got_nonzero <= '1';

                                -- Start updating a display character
                                display_char_start <= '1';
                                curr_state <= DISPLAY_WAIT;
                                next_state <= DISPLAY_FREQ_INTEGER;
                            else
                                -- just loop back
                                curr_state <= DISPLAY_FREQ_INTEGER;
                            end if;
                        -- We are always displaying the digit, regardless
                        --  of nonzero
                        else
                            display_char_start <= '1';
                            curr_state <= DISPLAY_WAIT;
                            
                            --Now, figure out what to do next. 
                            if (conv_integer(frq_counter) = 0) then
                                next_state <= DISPLAY_FREQ_DECIMAL;
                                frq_counter <= "0011";
                                display_char <= "01101";
                            else
                                next_state <= DISPLAY_FREQ_INTEGER;
                                frq_counter <= frq_counter - 1;
                                display_char <= display_char + 1;
                            end if;

                        end if;

                    --
                    -- Display all decimal digits
                    --
                    when DISPLAY_FREQ_DECIMAL =>
                        -- make the high bits of the display data equal to 0x3 so that
                        --  we can just tack the integer onto the end to make an ASCII-encoded
                        --  integer
                        display_data(7 downto 4) <= "0011";

                        -- Get the current decimal digit
                        frq_digit := bcd_freq((4*conv_integer(frq_counter) + 3) downto (4*conv_integer(frq_counter)));

                        -- Since we display all digits, we do not need to check for leading zeroes
                        --  or anything. We do, however, need to check to see if we are auto tuning, 
                        --  because if we are auto tuning then we need to progress to auto 
                        --  tune, otherwise we are done.
                        if (conv_integer(frq_counter) = 0) then
                            if (auto_tune = '1') then
                                next_state <= DO_AUTO_TUNE;
                            else
                                next_state <= IDLE;
                            end if;
                        else
                            next_state <= DISPLAY_FREQ_DECIMAL;
                            frq_counter <= frq_counter - 1;
                            display_char <= display_char + 1;
                        end if;

                        -- Always start a character update and then wait
                        curr_state <= DISPLAY_WAIT;
                        display_char_start <= '1';

                    when DO_AUTO_TUNE =>
                        auto_start <= '1';
                        curr_state <= AUTO_TUNE_WAIT;

                    when AUTO_TUNE_WAIT =>

                        if (auto_done = '1') then

                            -- If we need to try again, then do so
                            if (tuned = '0') then
                                -- and restart the sampling process!
                                sample_start <= '1';
                                curr_state <= RUN_SAMPLING;
                            -- otherwise, we're done!
                            else
                                curr_state <= IDLE;
                            end if;

                        else
                            -- otherwise, wait here.
                            curr_state <= AUTO_TUNE_WAIT;
                        end if;

                    --
                    -- Catch-ALL for init
                    --
                    when others =>
                        curr_state <= IDLE;

                end case;

            end if;

        end if;

    end process;

end architecture;













