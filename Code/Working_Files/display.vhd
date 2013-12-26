--
-- This is the display controller for 
--	the LCD character display
--
-- The Display controller will take a
--	16-bit FIFO as input. Words will
--	be written to the FIFO in the 
--	following manner:
--
--	15	14	13	12	11	10	9	8	7	6	5	4	3	2	1	0
-- |   row    |       column     |      ASCII character value     |
--
-- The row will be range 1-4, the column will be range 0 - 19 and
--	the ascii character will be range 0 - 255.
--
-- If the row is ever 0, then this indicated that the system should
--	go through the reset cycle 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work;
use work.display_constants.all;
use work.display_fifo;

entity DISPLAY is 
	
	port (

		-- System clock
		clk		: in std_logic;

		-- I/O to the display
		lcd_rs      : out std_logic;
        lcd_rw      : out std_logic;
        lcd_e       : out std_logic;
        lcd_data    : out std_logic_vector(7 downto 0);

        -- FIFO input from freq_convert
        fifo_wr_en 		: in std_logic;
        fifo_wr_data 	: in std_logic_vector(15 downto 0);
        fifo_full		: out std_logic;

        n_reset 		: in std_logic

	);

end DISPLAY;

--
-- Put together the architecture of the display. The FIFO
--	writes are clocked on the system clock
--
architecture behavioral of DISPLAY is 
	
	-- Signals to hook up the display FIFO
	signal fifo_ack : std_logic;
	signal fifo_dout : std_logic_vector(15 downto 0);
	signal fifo_empty : std_logic;

	signal row		: std_logic_vector(2 downto 0);
	signal column 	: std_logic_vector(4 downto 0);
	signal disp_reset : std_logic;
	signal data 	: std_logic_vector(7 downto 0);
	
	-- Signals for making the display clock
	signal disp_clk 		: std_logic;
	signal disp_clk_counter : std_logic_vector(11 downto 0);
	signal disp_clk_inc 	: std_logic_vector(11 downto 0);

	-- LCD address
	signal lcd_line_start 	: std_logic_vector(6 downto 0);

	type disp_states is (
		IDLE, 
		DO_RESET, 
		SEND_ADDR_SET_RS,
		SEND_ADDR_SET_DATA,
		SEND_ADDR_DROP_EN,
		SEND_DATA_SET_RS,
		SEND_DATA_SET_DATA,
		SEND_DATA_DROP_EN
	);

	signal curr_state : disp_states;

	-- Need a counter for the reset. Reset takes something
	--	like 116 display clocks
	signal reset_count : std_logic_vector(7 downto 0);

	signal fifo_reset : std_logic;

begin

	--
	-- We are always writing to the display, 
	--	never reading from it
	--
	lcd_rw <= '0';

	--
	-- The FIFO needs an active high reset
	-- 
	fifo_reset <= not n_reset;

	-- Declare the display FIFO
	dispFIFO: entity DISPLAY_FIFO
		port map(
			rst  	=> fifo_reset,  
			wr_clk	=> clk,
			rd_clk	=> disp_clk,
			din  	=> fifo_wr_data,  
			wr_en 	=> fifo_wr_en,
			rd_en 	=> fifo_ack, 
			dout 	=> fifo_dout, 
			full 	=> fifo_full, 
			empty 	=> fifo_empty 
		);

	--
	-- Break down the fifo data out into the line_start column, data and reset signals
	--
	lcd_line_start 	<= 	line_0_start when std_match(fifo_dout(15 downto 13), "001") else -- line 1
						line_1_start when std_match(fifo_dout(15 downto 13), "010") else -- line 2
						line_2_start when std_match(fifo_dout(15 downto 13), "011") else -- line 3
						line_3_start;													  -- line 4 / reset

	column 			<= fifo_dout(12 downto 8);
	data 			<= fifo_dout(7 downto 0);
	disp_reset 		<= 	'1' when std_match(fifo_dout(15 downto 13), "000") else
						'0';

	--
	-- Make the display clock
	--
	disp_clk_inc <= std_logic_vector(unsigned(disp_clk_counter) + 1);

	makeDispClk: process(clk)
	begin
		if (rising_edge(clk)) then
			if (n_reset = '0') then
				disp_clk_counter <= (others => '0');
				disp_clk 		 <= '0';
			else
				disp_clk_counter <= disp_clk_inc;
				disp_clk 		 <= disp_clk_inc(11);
			end if;
		end if;
	end process;

	--
	-- State machine to control the display controller
	--
	doDisplay: process(disp_clk)
	begin

		if (rising_edge(disp_clk)) then
			-- Break out the different display states
			case curr_state is

				--
				-- Wait for the FIFO to be non-empty
				--
				when IDLE => 

					-- Always send the read acknowledge low
					fifo_ack <= '0';

					-- If the fifo is non-empty and not reset, then
					--	latch the data and send it out
					if (fifo_empty = '0') then
						if (disp_reset = '1') then
							curr_state <= DO_RESET;
						else
							curr_state <= SEND_ADDR_SET_RS;
						end if;
					-- Otherwise, just stay in IDLE and reset the enable
					--	and the FIFO ack
					else
						curr_state <= IDLE;
						lcd_e 	<= '0';
						reset_count <= (others => '0');
					end if;

				--
				-- Perform the reset
				--

				when DO_RESET =>

					-- The RS line is always 0 on reset
					lcd_rs <= '0';

					-- 
					-- Which data to put on the line
					--
					if( 	(unsigned(reset_count) = 112) or
							(unsigned(reset_count) = 113) ) then
						lcd_data <= reset_reg_function_set;
					elsif( 	(unsigned(reset_count) = 114) or
							(unsigned(reset_count) = 115) ) then
						lcd_data <= reset_display_set;
					elsif( 	(unsigned(reset_count) = 116) or
							(unsigned(reset_count) = 117) ) then 
						lcd_data <= reset_entry_mode_set;
					elsif( 	(unsigned(reset_count) = 118) or
							(unsigned(reset_count) = 119) ) then
						lcd_data <= reset_display_clear;
					else
						lcd_data <= reset_special_function_set;
					end if;

					--
					-- What to do with the enable. Can go high
					--	on the same clock that the new data goes high.
					--
					if ((unsigned(reset_count) = 1) or	
						(unsigned(reset_count) = 104) or	
						(unsigned(reset_count) = 108) or	
						(unsigned(reset_count) = 112) or	
						(unsigned(reset_count) = 114) or
						(unsigned(reset_count) = 116) or
						(unsigned(reset_count) = 118) ) then

						lcd_e <= '1';
					else
						lcd_e <= '0';
					end if;

					-- Need to send the fifo acknowledge high for 
					--	one clock right before the end of the
					--	cycle. Want the new data/empty available in IDLE
					if (unsigned(reset_count) = 149) then
						fifo_ack <= '1';
					else
						fifo_ack <= '0';
					end if;

					-- Use the entire span of the reset counter to give the display
					--	adequate time to clear. 
					if (unsigned(reset_count) = 150) then
						curr_state <= IDLE;
						reset_count <= (others => '0');
					else
						curr_state <= DO_RESET;
						reset_count <= std_logic_vector(unsigned(reset_count) + 1);
					end if;


				-- Set the register select line low 
				-- RS = 0, RW = 0, E = 0, data = X
				when SEND_ADDR_SET_RS =>

					lcd_rs <= '0';
					curr_state <= SEND_ADDR_SET_DATA;

				-- Put the enable high and put out valid data
				-- RS = 0, RW = 0, E = 1, data = Valid
				when SEND_ADDR_SET_DATA =>
					lcd_e <= '1';
					lcd_data(6 downto 0) <= std_logic_vector(unsigned(lcd_line_start) + ("0" & unsigned(column)));
					lcd_data(7) <= '1';
					curr_state <= SEND_ADDR_DROP_EN;

				-- Drop the enable
				-- RS = 0, RW = 0, E = 0, data = Valid
				when SEND_ADDR_DROP_EN =>
					lcd_e <= '0';
					curr_state <= SEND_DATA_SET_RS;

				-- Set RS to 1 for the data
				-- RS = 1, RW = 0, E = 0, data = X
				when SEND_DATA_SET_RS =>
					lcd_rs <= '1';
					curr_state <= SEND_DATA_SET_DATA;

				-- Send the display data
				-- RS = 1, RW = 0, E = 1, data = Valid
				--
				-- Need the acknowledge to be high
				--	for the clock before reset so
				--	that we can have the right
				--	data/empty value back in idle
				when SEND_DATA_SET_DATA =>
					lcd_e <= '1';
					lcd_data <= data;
					fifo_ack <= '1';
					curr_state <= SEND_DATA_DROP_EN;

				-- Drop the enable, send the fifo acknowledge back down 
				--	and return to idle
				-- RS = 1, RW = 0, E = 0, data = Valid
				when SEND_DATA_DROP_EN =>
					lcd_e <= '0';
					fifo_ack <= '0';
					curr_state <= IDLE;

				--
				-- Default: go back to IDLE
				--
				when others =>
					curr_state <= IDLE;

			end case;

		end if;

	end process;

end architecture;


















