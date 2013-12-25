--
-- This is a quick project file to test the display module
--	on-target
--

library work;
use work.display;
use work.debounce;
use work.display_constants.all;


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

-- Entity declaration
entity disp_test is 
    
    port(

        -- system clock
        clk         : in  std_logic;

        -- pushbuttons
        btn         : in  std_logic_vector(5 downto 0);
        -- leds
        led         : out std_logic_vector(7 downto 0);

        -- LCD signals
		lcd_rs  	: out std_logic;
		lcd_rw  	: out std_logic;
		lcd_e   	: out std_logic;
		lcd_data	: out std_logic_vector(7 downto 0)

    );

end disp_test;

architecture structural of disp_test is 

	-- Signals for the FIFO
	signal disp_wr_en 	: std_logic;
	signal disp_data 	: std_logic_vector(15 downto 0);

	-- Debounced Buttons
	signal db_buttons	: std_logic_vector(5 downto 0);

	signal disp_counter : std_logic_vector(6 downto 0);

	signal button_latch_1 : std_logic_vector(4 downto 0);
	signal button_latch_2 : std_logic_vector(4 downto 0);

	--
	-- For checking that debouncing is working
	--
	signal new_button_latch_1 : std_logic_vector(5 downto 0);
	signal new_button_latch_2 : std_logic_vector(5 downto 0);
	signal curr_button  : std_logic_vector(5 downto 0);
	signal button_count	: std_logic_vector(4 downto 0);

	signal done_burst 	: std_logic;
	signal fifo_full	: std_logic;
	signal disp_reset 	: std_logic;

begin

	--
	-- Display Unit
	--
	dsply: entity DISPLAY
		port map(
					
			clk				=> clk,
			lcd_rs      	=> lcd_rs,
	        lcd_rw      	=> lcd_rw,
	        lcd_e       	=> lcd_e,
	        lcd_data    	=> lcd_data,
			fifo_wr_en 		=> disp_wr_en,
	        fifo_wr_data 	=> disp_data,
	        fifo_full		=> fifo_full,
			reset 			=> disp_reset
		);

	-- Display needs an active-high reset
	disp_reset <= not btn(0);

	--
	-- Button Debouncer
	--
    dbounce: entity DEBOUNCE
	    port map(
	        clock       => clk,
	        buttons     => btn,
	        button_0    => db_buttons(0),
	        button_1    => db_buttons(1),
	        button_2    => db_buttons(2),
	        button_3    => db_buttons(3),
	        button_4    => db_buttons(4),
	        button_5    => db_buttons(5)
	    );


	--
	-- Logic for the test. First, send a display reset. Then
	--	Fill the display with a burst write. 
	-- Finally, put one character per button pressed onto the 
	--	display.
	doDisp: process(clk)
	begin

		if (rising_edge(clk)) then
			-- Latch the buttons to catch a rising edge
            button_latch_1 <= db_buttons(5 downto 1);
            button_latch_2 <= button_latch_1;

			-- We got a reset button
			if (btn(0) = '0') then
				disp_counter <= (others => '0');
				disp_wr_en <= '0';
				done_burst <= '0';
			else
				-- For the first 81 clocks, send the reset and 
				-- fill the display
				if ((fifo_full = '0') and (done_burst = '0')) then

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
						done_burst <= '1';
					else
						disp_counter <= std_logic_vector(unsigned(disp_counter) + 1);
					end if;

				--
				-- Now that we have enqueued the full array of characters, we want to enqueue
				--	a character for each button pressed
				--

	            -- If we got a rising edge on a new button
	            elsif ( (not std_match(((button_latch_1 xor button_latch_2) and (button_latch_2)), "00000" ) ) and (fifo_full = '0')) then

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
	            	if (button_latch_2(0) = '1') then
	            		disp_data(7 downto 0) <= X"55";
	            	elsif(button_latch_2(1) = '1') then
	            		disp_data(7 downto 0) <= X"4C";
	            	elsif(button_latch_2(2) = '1') then
	            		disp_data(7 downto 0) <= X"44";
	            	elsif(button_latch_2(3) = '1') then
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

	led(7) <= fifo_full;
	led(6) <= disp_wr_en;
	led(5 downto 0) <= btn(5 downto 0);



end architecture;



						



