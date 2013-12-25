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
		disp_fifo_full	: in std_logic

	); 

end USER_INTERFACE;


architecture behavioral of USER_INTERFACE is
	
	-- Need a signal to see if we output the reset string
	--	after reset
	signal done_reset : std_logic;

	-- Need a display counter to help with the reset cycle
	--	and the cycling through buttons
	signal disp_counter : std_logic_vector(6 downto 0);

begin

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

            -- We got a reset 
            if (n_reset = '0') then
                disp_counter <= (others => '0');
                disp_wr_en <= '0';
                done_reset <= '0';
            else
                -- For the first 81 clocks, send the reset and 
                -- fill the display
                if ((disp_fifo_full = '0') and (done_reset = '0')) then

                    disp_wr_en <= '1';

                    -- On the fist clock, want to send the reset
                    if (unsigned(disp_counter) = 0) then
                        disp_data <= (others => '0');
                    elsif (unsigned(disp_counter) <= 20) then
                        disp_data(15 downto 8) <= std_logic_vector(("0" & unsigned(disp_counter)) + to_unsigned(31, 8));
                    elsif (unsigned(disp_counter) <= 40) then
                        disp_data(15 downto 8) <= std_logic_vector(("0" & unsigned(disp_counter)) + to_unsigned(43, 8));
                    elsif (unsigned(disp_counter) <= 60) then
                        disp_data(15 downto 8) <= std_logic_vector(("0" & unsigned(disp_counter)) + to_unsigned(55, 8));
                    elsif (unsigned(disp_counter) <= 80) then
                        disp_data(15 downto 8) <= std_logic_vector(("0" & unsigned(disp_counter)) + to_unsigned(67, 8));
                    end if;

                    -- The display data is always the same
                    disp_data(7 downto 0) <= reset_string(to_integer(unsigned(disp_counter) - 1));

                    if (unsigned(disp_counter) = 80) then
                        disp_counter <= (others => '0');
                        done_reset <= '1';
                    else
                        disp_counter <= std_logic_vector(unsigned(disp_counter) + 1);
                    end if;

                --
                -- Now that we have enqueued the full array of characters, we want to enqueue
                --  a character for each button pressed
                --

                -- If we got a rising edge on a new button
                elsif ( (not std_match(db_buttons, "00000")) and (disp_fifo_full = '0') ) then

                    -- Enable writing to the display
                    disp_wr_en <= '1';

                    if (unsigned(disp_counter) < 20) then
                        disp_data(15 downto 8) <= std_logic_vector(("0" & unsigned(disp_counter)) + to_unsigned(32, 8));
                    elsif (unsigned(disp_counter) < 40) then
                        disp_data(15 downto 8) <= std_logic_vector(("0" & unsigned(disp_counter)) + to_unsigned(44, 8));
                    elsif (unsigned(disp_counter) < 60) then
                        disp_data(15 downto 8) <= std_logic_vector(("0" & unsigned(disp_counter)) + to_unsigned(56, 8));
                    elsif (unsigned(disp_counter) < 80) then
                        disp_data(15 downto 8) <= std_logic_vector(("0" & unsigned(disp_counter)) + to_unsigned(68, 8));
                    end if;

                    -- Write the button's ASCII code (U, D, L, R, C) to the display
                    if (db_buttons(0) = '1') then
                        disp_data(7 downto 0) <= X"55";
                    elsif(db_buttons(1) = '1') then
                        disp_data(7 downto 0) <= X"4C";
                    elsif(db_buttons(2) = '1') then
                        disp_data(7 downto 0) <= X"44";
                    elsif(db_buttons(3) = '1') then
                        disp_data(7 downto 0) <= X"52";
                    else
                        disp_data(7 downto 0) <= X"43";
                    end if;

                    if (unsigned(disp_counter) = 79) then
                        disp_counter <= (others => '0');
                    else
                        disp_counter <= std_logic_vector(unsigned(disp_counter) + 1);
                    end if;

                else
                    
                    disp_wr_en <= '0';

                end if;

            end if;

        end if;

    end process;

end architecture;
