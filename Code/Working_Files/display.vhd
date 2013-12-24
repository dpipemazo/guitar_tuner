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
        fifo_wr_data 	: in std_logic_vector(15 downto 0)

	);

end DISPLAY;

--
-- Put together the architecture of the display. The FIFO
--	writes are clocked on the system clock
--
architecture behavioral of DISPLAY is 
	
	-- Signals to hook up the display FIFO
	signal fifo_rst : std_logic;
	signal fifo_ack : std_logic;
	signal fifo_dout : std_logic_vector(15 downto 0);
	signal fifo_full : std_logic;
	signal fifo_empty : std_logic;

	signal row		: std_logic_vector(2 downto 0);
	signal column 	: std_logic_vector(4 downto 0);
	signal reset 	: std_logic;
	signal data 	: std_logic_vector(7 downto 0);
	
	-- Signals for making the display clock
	signal disp_clk 		: std_logic;
	signal disp_clk_counter : std_logic_vector(9 downto 0);
	signal disp_clk_inc 	: std_logic_vector(9 downto 0);

	-- LCD address
	signal lcd_line_start 	: std_logic_vector(6 downto 0);

	type disp_states is (
		IDLE, 
		RESET, 
		SEND_ADDR,
		SEND_DATA
	);

	signal curr_state : disp_states;

begin

	--
	-- We are always writing to the display, 
	--	never reading from it
	--
	lcd_rw <= '0';

	-- Declare the display FIFO
	dispFIFO: entity DISPLAY_FIFO
		port map(
			rst  	=> fifo_rst,  
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
	lcd_line_start 	<= 	"0000000" when std_match(fifo_dout(15 downto 13), "001") else -- line 1
						"1000000" when std_match(fifo_dout(15 downto 13), "010") else -- line 2
						"0010100" when std_match(fifo_dout(15 downto 13), "011") else -- line 3
						"1010100";													  -- line 4 / reset

	column 			<= fifo_dout(12 downto 8);
	data 			<= fifo_dout(7 downto 0);
	reset 			<= 	'1' when std_match(fifo_dout(15 downto 13), "000") else
						'0';

	--
	-- Make the display clock
	--
	disp_clk_inc <= std_logic_vector(unsigned(disp_clk_counter) + 1);

	makeDispClk: process(clk)
	begin
		if (rising_edge(clk)) then
			disp_clk_counter <= disp_clk_inc;
			disp_clk 		 <= disp_clk_inc(9);
		end if;
	end process;

	--
	-- State machine to control the display controller
	--
	doDisplay: process(disp_clk)
	begin

		-- Break out the different display states
		case curr_state is

			--
			-- Wait for the FIFO to be non-empty
			--
			when IDLE => 

				-- If the fifo is non-empty and not reset, then
				--	latch the data and send it out
				if (fifo_empty = '0') then
					if (reset = '1') then
						curr_state <= RESET;
					else
						curr_state <= SEND_ADDR;
					end if;
				-- Otherwise, just stay in IDLE and reset the enable
				--	and the FIFO ack
				else
					curr_state <= IDLE;
					lcd_e 	<= '0';
					ffo_ack <= '0';
				end if;

			--
			-- Perform the reset
			--
			when RESET =>

				--
				-- Do some reset shit
				--	and then go back to IDLE
				--
				curr_state <= IDLE;

			--
			-- Send out the new address based 
			--	on the data
			--

			-- Set the register select line low 
			when SEND_ADDR_SET_RS =>

				lcd_rs <= '0';
				curr_state <= SEND_ADDR_SET_DATA;

			-- Send the enable high and put the data
			--	on the line
			when SEND_ADDR_SET_DATA =>
				lcd_e <= '1';
				lcd_data <= std_logic_vector(unsigned(lcd_line_start) + ("0" & unsigned(column)));


			--
			-- Send out the new data
			--
			when SEND_DATA =>

				-- Send out the data and then reset back to IDLE
				curr_state <= IDLE;

			--
			-- Default: go back to IDLE
			--
			when others =>
				curr_state <= IDLE;

		end case;

	end process;


















