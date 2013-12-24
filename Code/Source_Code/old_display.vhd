--
-- DISPLAY.vhd
--
-- This is the display controller. Hopefully putting things
--  here will make the whole control block less of a shitshow
--  and more straightforward. I do not look forward to this
--  overhaul
--
--
-- The system has the following functionality:
--  1. Line update:
--      take a preprogrammed line from FLASH memory and put it on a particular
--      line of the display.
--          --> the top 
--  2. Character update:
--      take an input character and put it at a certain display address

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.display_constants.all;

entity DISPLAY is 
    
    port(
        clk     : in std_logic;

        -- display I/O
        lcd_rs      : out std_logic;
        lcd_rw      : out std_logic;
        lcd_e       : out std_logic;
        lcd_data    : out std_logic_vector(7 downto 0);

        -- Serial I/O
        FlashCLK        : out std_logic; 
        FlashCS         : out std_logic;   
        FlashDQ0        : out std_logic;
        FlashDQ1        : in std_logic;

        -- Commands to/from the control unit
        start_line_update   : in std_logic;
        start_char_update   : in std_logic;
        do_reset            : in std_logic;
        done                : out std_logic;
        command_ack         : out std_logic;

        -- User input, either the character to put on the LCD (ASCII encoded) 
        -- or the string to take from memory (range 0 - 63)
        display_data        : in std_logic_vector(7 downto 0);
        -- User input, which line to do the update on (range 0 - 3)
        line_to_update      : in std_logic_vector(1 downto 0);
        -- User input, which character to update (if char mode), range 0 - 19
        char_to_update      : in std_logic_vector(4 downto 0)
    );
end DISPLAY;

architecture behavioral of DISPLAY is 
    
    --
    -- GENERAL STATE MACHINE SIGNALS
    --

    -- The current state
    signal curr_state : display_states;
    -- A holder for the state after a generic 
    --  state so that we can reuse states
    signal next_state : display_states;

    -- Counter to reduce states so that we can toggle signals
    --  as we need without going through a million states
    signal state_count : std_logic_vector(9 downto 0);
    signal state_count_result : std_logic_vector(9 downto 0);
    shared variable state_count_state : state_count_states;

    --
    -- Wait count and force update
    --
    signal wait_count : std_logic_vector(9 downto 0);

    --
    -- SIGNALS FOR LCD_SET_ADDRESS
    --
    signal new_address : std_logic_vector(6 downto 0);
    signal line_start : std_logic_vector(6 downto 0);


    --
    -- SIGNALS FOR SEND_CHAR
    --
    signal send_char_data : std_logic_vector(7 downto 0);

    --
    -- SIGNALS FOR SERIAL_GET_CHAR
    --
    signal serial_buffer : std_logic_vector(7 downto 0);
    signal serial_count : std_logic_vector(4 downto 0);
    signal serial_address : std_logic_vector(23 downto 0);
    signal serial_chars_sent : std_logic_vector(4 downto 0);

    --
    -- SIGNALS FOR LCD RESET
    --
    signal reset_count : std_logic_vector(3 downto 0);

    --
    -- Signals for control lines
    --
    signal control_lines : std_logic_vector(2 downto 0);

begin

    --
    -- Asynchronously decode LCD lines to start addresses 
    --  so that they can be used across multiple states
    --
    line_start <=   line_0_start when (line_to_update = "00") else
                    line_1_start when (line_to_update = "01") else
                    line_2_start when (line_to_update = "10") else
                    line_3_start;

    --
    -- Asynchronously put together the serial address lines, 
    --  using line_num and the string number as the final 
    --  10 bits and beginning at 0x800000.
    --
    serial_address <= "10000000000000" & line_to_update & display_data;


    -- the state machine runs on clock edges. This clock is expected to 
    --  be a slowed display clock running at 200KHz (195312.5KHz exactly). If the clock is not 
    --  running at 200KHz, the "wait" counts for the LCD need to be updated to match
    --  the new clock
    process(clk)

    begin

        if (rising_edge(clk)) then

            case curr_state is 

                --
                -- IDLE state. 
                -- Reset the state counter and wait for something 
                --  interesting to happen
                --
                when IDLE =>

                    --
                    -- Initializations
                    --
                    state_count <= (others => '0');
                    serial_count <= (others => '0');
                    reset_count <= (others => '0');
                    FlashCS <= '1';
                    lcd_e <= '0';
                    done <= '0';


                    -- 
                    -- Go to the correct state based on input
                    --  signal. Names are fairly obvious
                    --
                    case control_lines is 
                        -- Reset and only reset high
                        when "100" =>
                            curr_state <= RESET;
                            command_ack <= '1';
                        -- start_line_update only one high
                        when "010" =>
                            curr_state <= UPDATE_LINE;
                            command_ack <= '1';
                        -- update_char only one high
                        when "001" =>
                            curr_state <= UPDATE_CHAR;
                            command_ack <= '1';
                        -- otherwise, just chill in IDLE
                        when others =>
                            curr_state <= IDLE;
                            command_ack <= '0';
                    end case;

                --
                -- Begin the process for updating a line by 
                --  updating the LCD data address to the 
                --  beginning of the line and then jumping to
                --  the serial read/send loop.
                --
                when UPDATE_LINE =>

                    -- Get rid of the acknowledge
                    command_ack <= '0';

                    -- Need to set the LCD memory address
                    --  to the beginning of the line which
                    --  we need to update
                    new_address <= line_start;
                    -- After setting the new address, go onto 
                    --  get the first character for the line from
                    --  the flash memory.
                    next_state <= SERIAL_GET_CHAR;
                    -- Actually update the line.
                    curr_state <= LCD_SET_ADDRESS;

                --
                -- Begin the process ofr updating a char by 
                --  updating the LCD data address to the correct character
                --  and then jumping to loading the character 
                --  data onto the LCD lines.
                --
                when UPDATE_CHAR =>

                    -- Get rid of the acknowledge
                    command_ack <= '0';

                    -- Add the character offset to the line start
                    new_address <= line_start + char_to_update;
                    -- After sending the address, want to go to LCD_SET_DATA
                    --  in order to load the character onto the data lines 
                    --  before calling SEND_CHAR
                    next_state <= UPDATE_CHAR_DATA;
                    -- Update the address
                    curr_state <= LCD_SET_ADDRESS;

                --
                -- Put the data in the right place for send_char and then
                -- call send_char
                --
                when UPDATE_CHAR_DATA =>
                    send_char_data <= display_data;
                    next_state <= STATE_DONE;
                    curr_state <= LCD_SEND_CHAR;

                --
                -- Set the LCD starting address to new_address
                --
                when LCD_SET_ADDRESS =>

                    -- First clock
                    if (conv_integer(state_count) = 0) then
                        -- Set up control signals
                        lcd_rs <= '0';
                        lcd_rw <= '0';

                        -- increment the state count and
                        --  loop back
                        state_count <= state_count + 1;
                        curr_state <= LCD_SET_ADDRESS;


                    -- Second clock
                    else
                        -- Set up the LCD enable and data
                        lcd_e <= '1';
                        lcd_data <= '1' & new_address;

                        -- Reset the state count, 
                        --  set the wait count and 
                        -- jump to the wait state
                        state_count <= (others => '0');
                        wait_count <= wait_37_us;
                        curr_state <= LCD_WAIT;
                    end if;

                --
                -- Wait for the specified number
                --  of clocks then jump to next_state
                --
                when LCD_WAIT =>

                    -- Send the enable low
                    lcd_e <= '0';

                    -- Figure out if we've waited long enough
                    if (conv_integer(state_count) = conv_integer(wait_count)) then
                        state_count <= (others => '0');
                        curr_state <= next_state;
                    else
                        state_count <= state_count + 1;
                        curr_state <= LCD_WAIT;
                    end if;

                --
                -- Send the character on the send_char
                --  data line to the LCD
                --
                when LCD_SEND_CHAR =>

                    -- First clock
                    if (conv_integer(state_count) = 0) then
                        state_count <= state_count + 1;

                        -- Set up the control signals
                        lcd_rw <= '0';
                        lcd_rs <= '1';
                        -- And loop back
                        curr_state <= LCD_SEND_CHAR;

                    -- Second clock
                    else
                        state_count <= (others => '0');

                        -- set up the data and enable
                        lcd_data <= send_char_data;
                        lcd_e <= '1';

                        -- Set up the wait count
                        wait_count <= wait_37_us;

                        -- And go do the wait
                        curr_state <= LCD_WAIT;
                    end if;
                
                --
                -- Get a character from the serial controller
                --
                when SERIAL_GET_CHAR =>

                    case conv_integer(state_count) is

                        -- First clock
                        when 0 =>
                            -- Initialize the control signals
                            FlashCS <= '0';
                            FlashCLK <= '0';
                            -- Initialize the serial count to the number of 
                            --  bits in the serial instruction
                            serial_count <= serial_instr_bits;
                            -- And increment the state count
                            state_count <= state_count + 1;

                        --
                        -- The next two statements serve as the loop for 
                        --  sending the read instruction
                        --

                        -- Set up the clock and put the instruction data on the line
                        when 1 =>
                            -- Send the serial clock low
                            FlashCLK <= '0';
                            -- Put the instruction bit on the line
                            FlashDQ0 <= serial_read_instr(conv_integer(serial_count));
                            -- And increment the state count
                            state_count <= state_count + 1;

                        -- send the clock high and figure out what to do next
                        when 2 => 
                            -- Set the serial clock high
                            FlashCLK <= '1';
                           
                            -- Figure out what to do next
                            if (conv_integer(serial_count) = 0) then
                                -- Jump to the next loop
                                state_count <= state_count - 1;
                                serial_count <= serial_addr_bits;
                            else
                                -- Jump to the beginning of this loop
                                state_count <= state_count - 1;
                                serial_count <= serial_count - 1;
                            end if;

                        --
                        -- The next two statements serve as the loop for sending
                        --  the read address
                        --

                        -- Set up the clock and put the address data on the line
                        when 3 => 
                            -- Send the serial clock low
                            FlashCLK <= '0';
                            -- Put the address bit on the line
                            FlashDQ0 <= serial_address(conv_integer(serial_count));
                            -- and increment the state count
                            state_count <= state_count + 1;

                        -- Send the clock high and figure out what to do next
                        when 4 =>
                            -- Send the serial clock high
                            FlashCLK <= '1';

                            -- Figure out what to do next
                            if (conv_integer(serial_count) = 0) then
                                -- Jump to the next loop
                                state_count <= state_count + 1;
                                serial_count <= serial_char_bits;
                            else
                                state_count <= state_count + 1;
                                serial_count <= serial_count - 1;
                            end if;

                        --
                        -- The next two statements serve as the loop for 
                        --  reading in the serial data
                        --
                        when 5 =>
                            -- Send the clock low
                            FlashClk <= '0';
                            -- And increment the state count
                            state_count <= state_count + 1;

                        when 6 =>
                            -- Send the clock high
                            FlashCLK <= '1';
                            -- Grab the bit of data from the line and put it into
                            --  the serial buffer
                            serial_buffer(conv_integer(serial_count)) <= FlashDQ1;

                            -- Figure out what to do next
                            if (conv_integer(serial_count) = 0) then
                                -- If we have gotten all of the data then send the
                                --  character
                                send_char_data <= serial_buffer;
                                curr_state <= LCD_SEND_CHAR;
                                state_count <= (others => '0');

                                -- Now if this is the final character, finish and go to IDLE, 
                                -- else jump back to serial_get_char
                                if (conv_integer(serial_chars_sent) = (serial_char_num - 1)) then
                                    next_state <= STATE_DONE;
                                    serial_chars_sent <= (others => '0');
                                else
                                    next_state <= SERIAL_GET_CHAR;
                                    serial_chars_sent <= serial_chars_sent + 1;
                                end if;

                            else
                                -- Otherwise loop until we have a full buffer
                                state_count <= state_count - 1;
                                serial_count <= serial_count - 1;
                            end if;

                        -- Should never execute this
                        when others => 
                            state_count <= (others => '0');
                            curr_state <= SERIAL_GET_CHAR;

                    end case;

                --
                -- If we're done, then just send done high and jump to IDLE
                --
                when STATE_DONE =>
                    done <= '1';
                    curr_state <= IDLE;

                --
                -- The RESET cycle
                --
                when RESET =>

                    -- Set up the data, control signals and 
                    --  wait times
                    case conv_integer(reset_count) is

                        -- First RESET operation, get the 
                        --  LCD signals ready for reset
                        when 0 => 
                            -- Set the lcd control signals
                            lcd_rs <= '0';
                            lcd_rw <= '0';

                        -- Send the first special function set and wait for 
                        --  4.1 ms
                        when 1 =>
                            -- Set the data
                            lcd_data <= reset_special_function_set;
                            -- Set the wait time
                            wait_count <= wait_4_ms;

                        -- Send the second and third special function set and wait for 
                        --  100 us
                        when 2 to 3 =>
                            -- Set the data
                            lcd_data <= reset_special_function_set;
                            -- Set the wait time
                            wait_count <= wait_100_us;

                        -- Send the actual function set and wait for 37 us
                        when 4 =>
                            -- Set the data
                            lcd_data <= reset_reg_function_set;
                            -- Set the wait time
                            wait_count <= wait_37_us;

                        -- Send the display set and wait for 37 us
                        when 5 =>
                            -- Set the data
                            lcd_data <= reset_display_set;
                            -- Set the wait time
                            wait_count <= wait_37_us;

                        -- Send the display clear and wait for 37 us
                        when 6 =>
                            -- Set the data
                            lcd_data <= reset_display_clear;
                            -- Set the wait time
                            wait_count <= wait_37_us;

                        -- Send the entry mode set and wait for 37 us
                        when 7 =>
                            -- Set the data
                            lcd_data <= reset_entry_mode_set;
                            -- Set the wait time
                            wait_count <= wait_37_us;

                        when others =>
                            reset_count <= (others => '0');

                    end case;

                    --
                    -- Figure out what to do based on the 
                    --  value of the reset counter.
                    --
                    case conv_integer(reset_count) is
                        when 0 =>
                            lcd_e <= '0';
                            curr_state <= RESET;

                        when 7 =>
                            lcd_e <= '1';
                            curr_state <= LCD_WAIT;
                            next_state <= IDLE;

                        when others =>
                            lcd_e <= '1';
                            curr_state <= LCD_WAIT;
                            next_state <= RESET;
                    end case;

                    -- Always increment the reset count
                    reset_count <= reset_count + 1;

                    -- Get rid of the acknowledge
                    command_ack <= '0';

                --
                -- Perhaps on start-up or if something goes wrong, just chill
                --  in the idle state
                --
                when others =>
                    curr_state <= IDLE;

            end case;

        end if;

    end process;

end architecture;





























                







                        











