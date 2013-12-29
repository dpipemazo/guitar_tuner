--
-- This is the user interface VHD module
--
--	At this point in time, the user interface
--	does the following: 
--		1. Puts a reset string on the display after reset
--		2. Puts the letter corresponding to a button press 
--			on the display after a button press.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work;
use work.display_constants.all;

--
-- The entity declaration
--
entity USER_INTERFACE is
	
	port(

		-- System clock
		clk		: in std_logic;
		-- active-low reset
		n_reset	: in std_logic;

		-- Buttons
		db_buttons : in std_logic_vector(4 downto 0);

		-- Display output
		disp_wr_en 	: out std_logic;
		disp_data	: out std_logic_vector(15 downto 0);

		-- Display input
		disp_fifo_full	: in std_logic;

        -- String output
        current_string      : out std_logic_vector(2 downto 0);
        run_auto_tune       : out std_logic;
        -- Did we get tuned?
        tuned               : in std_logic

	); 

end USER_INTERFACE;


architecture behavioral of USER_INTERFACE is

    -- The current state of the user interface
    signal curr_string  : std_logic_vector(2 downto 0);
    signal auto_tune    : std_logic;

    -- If it is time to do a redraw
    signal redraw       : std_logic;
    signal redraw_row   : natural range 0 to 3;
    signal redraw_col   : natural range 0 to 19;


    -- Need a signal for toggling the auto tune
    signal run_auto_tune_sig : std_logic;

    signal do_reset   : std_logic;

    signal got_tuned  : std_logic;
begin

    -- Put the outputs out
    current_string      <= curr_string;
    run_auto_tune       <= run_auto_tune_sig;


	--
    -- Logic for the UI. First, send a display reset. Then
    --  Fill the display with the reset string (or nothing, 
    --  the display will be cleared after the reset)
    --
    -- Currently the buttons will put their respective ASCII
    --  character on the display beginning from the top left and
    --  working cross, then down and looping back to prove that
    --  every part of the display can be written to. 
    doDisp: process(clk)
    begin

        if (rising_edge(clk)) then

            -- We got a reset, so reset all of our
            --  variables and signals 
            if (n_reset = '0') then
                disp_wr_en              <= '0';
                curr_string             <= (others => '0');
                auto_tune               <= '0';
                redraw_row              <= 0;
                redraw_col              <= 0;
                redraw                  <= '0';
                do_reset                <= '1';
                run_auto_tune_sig       <= '0';
                got_tuned               <= '0';

            -- Send the reset command to the display unit and then
            --  trigger a normal redraw
            elsif ((do_reset = '1') and (disp_fifo_full = '0')) then
                do_reset    <= '0';
                disp_wr_en  <= '1';
                redraw      <= '1';
                disp_data   <= (others => '0');

            elsif ((redraw = '1') and (disp_fifo_full = '0')) then

                -- Turn on the display write enable
                disp_wr_en <= '1';

                -- Set up the row/column on the display lines
                disp_data(15 downto 13) <= std_logic_vector(to_unsigned(redraw_row + 1, 3));
                disp_data(12 downto 8)  <= std_logic_vector(to_unsigned(redraw_col, 5));

                --
                -- Put the data out based on the row
                --
                case redraw_row is 

                    -- Row 1: Which type of tuning mode we are in
                    when 0 =>
                        -- Free tune
                        if (unsigned(curr_string) = 0) then
                            disp_data(7 downto 0) <= free_tune_line(redraw_col);
                        -- Guitar tuning, need ot check for auto tuning or not
                        else
                            -- Need to output the correct string name in the correct place
                            if ((redraw_col = 10) or (redraw_col = 11)) then
                                disp_data(7 downto 0) <= strings(to_integer(unsigned(curr_string) - 1))(redraw_col - 10);
                            -- Otherwise, redo the filler for the string
                            else 
                                if (auto_tune = '0') then
                                    disp_data(7 downto 0) <= reg_tune_line(redraw_col);
                                else
                                    disp_data(7 downto 0) <= auto_tune_line(redraw_col);
                                end if;
                            end if;
                        end if;

                    -- Row 2: The reference frequency for our note
                    when 1 =>
                        if (unsigned(curr_string) = 0) then
                            disp_data(7 downto 0) <= X"20";
                        else
                            -- Need to output the correct string frequency in the correct place
                            if (redraw_col >= 12) then 
                                disp_data(7 downto 0) <= freqs(to_integer(unsigned(curr_string) - 1))(redraw_col - 12);
                            -- Output the template string
                            else 
                                disp_data(7 downto 0) <= target_freq_line(redraw_col);
                            end if;
                        end if;

                    -- Row 3: The input frequency
                    when 2 =>
                        disp_data(7 downto 0) <= input_freq_line(redraw_col);

                    -- Row 4: Used if in auto-tune mode or to display that we are tuned
                    when 3 =>
                        -- If we are not tuned
                        if (got_tuned = '0') then
                            if ((auto_tune = '1') and not (unsigned(curr_string) = 0)) then
                                if (run_auto_tune_sig = '0') then
                                    disp_data(7 downto 0) <= auto_tune_stopped(redraw_col);
                                else
                                    disp_data(7 downto 0) <= auto_tune_running(redraw_col);
                                end if;
                            else
                                disp_data(7 downto 0) <= X"20";
                            end if;
                        -- We are tuned!
                        else
                            disp_data(7 downto 0) <= tuned_line(redraw_col);
                        end if;
                            
                end case;

                --
                -- Increment the column and row counters
                --
                if(redraw_col = 19) then
                    if (redraw_row = 3) then
                        redraw <= '0';
                        redraw_row <= 0;
                    else
                        redraw_row <= redraw_row + 1;
                    end if;

                    redraw_col <= 0;
                else
                    redraw_col <= redraw_col + 1;
                end if;

            else
                -- turn off the write enable, that's all.
                disp_wr_en <= '0';
            end if;

            --
            -- Deal with button presses. 
            --

            if ( not std_match(db_buttons, "00000") ) then

                -- Run the auto tune or turn it off. 
                --  This signal will be an enable for
                --  the motors
                -- Up button
                if (db_buttons(0) = '1') then
                    if (auto_tune = '1') then
                        run_auto_tune_sig <= not run_auto_tune_sig;
                    end if;
                end if;

                -- Left button. Decrement the string
                if(db_buttons(1) = '1') then
                    if (unsigned(curr_string) = 0) then
                        curr_string <= std_logic_vector(to_unsigned(6, curr_string'length));
                    else
                        curr_string <= std_logic_vector(unsigned(curr_string) - 1);
                    end if;
                -- Right button. Increment the string
                elsif(db_buttons(3) = '1') then
                    if (unsigned(curr_string) = 6) then
                        curr_string <= (others => '0');
                    else
                        curr_string <= std_logic_vector(unsigned(curr_string) + 1);
                    end if;
                end if;

                -- Center button. Toggle auto-tune
                if(db_buttons(4) = '1') then
                    -- Always turn off the motors when entering/exiting
                    --  auto_tune.
                    run_auto_tune_sig <= '0';
                    auto_tune <= not auto_tune;
                end if;

                -- Down button. Clears the tuned message
                if(db_buttons(2) = '1') then
                    got_tuned <= '0';
                end if;

                -- Every time we get a button, redraw the display.
                redraw <= '1';

            -- If we got the tuned signal, do a redraw            
            elsif (tuned = '1') then
                -- Do the redraw
                redraw            <= '1';
                -- Note that we got tuned
                got_tuned         <= '1';
            end if;


        end if;

    end process;

end architecture;
