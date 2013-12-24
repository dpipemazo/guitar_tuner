--
-- This is the test bench for the display. It will work by
--	immediately filling the display fifo with a reset and then
--	writing characters beginning at ASCII zero to row 1, column 0
--	of the display and then incrementing across and down the 
--	display by one character and one ASCII character each time. 
--	Currently has manual verification that the signals are correct.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.display;

-- Test bench entity declaration
entity display_tb is 
end display_tb;

-- The architecture of the test bench
architecture behavioral of display_tb is

	-- The display component itself
	component DISPLAY is 
		
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

	end component;

	-- Signals to hook up to the display component
	signal test_clk				: std_logic;
	signal test_lcd_rs      	: std_logic;
	signal test_lcd_rw      	: std_logic;
	signal test_lcd_e       	: std_logic;
	signal test_lcd_data    	: std_logic_vector(7 downto 0);
	signal test_fifo_wr_en 		: std_logic;
	signal test_fifo_wr_data	: std_logic_vector(15 downto 0);

begin

	-- wire up the UUT
	UUT: DISPLAY
		port map(
			clk			 => test_clk,		
			lcd_rs       => test_lcd_rs,     
			lcd_rw       => test_lcd_rw,     
			lcd_e        => test_lcd_e,
			lcd_data     => test_lcd_data,   
			fifo_wr_en 	 => test_fifo_wr_en, 
			fifo_wr_data => test_fifo_wr_data
		);


	--
	-- Make the test clock
	--
	-- Make the system clock
	make_clock: process
	begin
        -- this process generates a 10 ns period, 50% duty cycle clock, 
        -- which is equivalent to the clock which we will have in our system. 
        test_clk <= '1';
        wait for 5 ns;

        test_clk <= '0';
        wait for 5 ns;

    end process; 

    --
    -- Actually test the display
    --
    testDisplay: process
    begin

    	-- Fisrt put the reset on the line
    	test_fifo_wr_en 	<= '1';
    	test_fifo_wr_data 	<= (others => '0');
    	wait for 10 ns;

    	-- Now, put the 80 characters into the fifo
    	for i in 0 to 79 loop

    		-- Do the row
    		test_fifo_wr_data(15 downto 13) <= std_logic_vector(to_unsigned((i/20) + 1, 3));
    		-- Do the column
    		test_fifo_wr_data(12 downto 8) <= std_logic_vector(to_unsigned(i mod 20, 5));
    		-- Do the character
    		test_fifo_wr_data(7 downto 0) <= std_logic_vector(to_unsigned((48 + i), 8));

    		wait for 10 ns;

    	end loop;

    end process;

end architecture;





