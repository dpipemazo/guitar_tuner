--
-- This file will convert an input frequency from 
--	a divider and bin value into a base 10 value. 
--	The output base 10 value will be 7 digits exactly
--	and will be in the form of XXXX.ZZZ where X 
--	is the integer part and Z the decimal. This 
--	unit is capable of converting the frequency
--	to 0.001 accuracy.
--
-- In order to perform the conversion, the input
--	divider and bin are sent as the divisor into 
--	the divider. The dividend is always the clock
--	speed of the sysem, 100MHz. This will output
--	a 28-bit result, of which we are only
--	interested in the bottom 14 bits (since our)
--	max frequency is 10KHz. We will also take the
--	10 bit fractional output of the divider.
--
-- These 24 bits will be fed into the conversion unit. 
--	This unit will perform the conversion from 24-
--	bit binary to XXXX.YYY characters for the display. 
--	The unit will enqueue the characters to be displayed
--	into the display FIFO as 16-bit words.
--
-- Words being enqueued into the display FIFO are of 
--	the following format:
--
--	15	14	13	12	11	10	9	8	7	6	5	4	3	2	1	0
-- |   row    |       column     |      ASCII character value     |
--
-- The upper 3 bits are the row (1 - 4), so that a bit is always 
--	set in the word being written for error-checking
-- The next 5 bits are the column (0 - 19)
-- The final 8 bits are the ASCII character value to be 
--	written to the display.
--
-- Note that the display FIFO has to be shared with the main 
--	control unit, so some scheme will have to be worked out 
--	for that as well.
--

--
-- Libraries
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work;
use work.freq_divider;

--
-- The entity declaration
--
entity FREQ_CONVERT is 
	
	port(
		-- System clock 
		clk 		: in std_logic;						-- system clock

		-- Results from the audio unit
		divider		: in std_logic_vector(11 downto 0); -- auto divider
		bin			: in std_logic_vector(10 downto 0); -- auto result
		sample_done : in std_logic;

		-- Output to the display FIFO
		disp_wr_en	: out std_logic;					-- active high
		disp_data	: out std_logic_vector(15 downto 0) -- data to be written to FIFO

	);

end entity;


--
-- The architecture
--
architecture behavioral of FREQ_CONVERT is	
	
	-- Multiplied result of the divider and the bin
	signal div_x_bin		: std_logic_vector(22 downto 0);
	-- Constant system clock speed
	constant sys_clk_spd 	: integer := 100000000;

	-- Divider signals
	signal freq_dividend	: std_logic_vector(27 downto 0);
	signal freq_divisor		: std_logic_vector(23 downto 0);
	signal freq_quotient	: std_logic_vector(27 downto 0);
	signal freq_fractional 	: std_logic_vector(9 downto 0);
	signal divide_rdy		: std_logic;
	signal divide_rfd 		: std_logic;
	signal divide_nd		: std_logic;


	-- Signals for conversion from binary to BCD
	signal do_convert			: std_logic; 	-- Latched output of divide_rdy. Should 
											--	pulse high for one clock.
	signal convert_done			: std_logic; 	-- Pulsed high for one clock when 
											-- the conversion is done
	signal convert_count		: std_logic_vector(4 downto 0);
	signal convert_val			: std_logic_vector(15 downto 0);
	signal latched_quotient		: std_logic_vector(13 downto 0);
	signal latched_fractional 	: std_logic_vector(9 downto 0);
	signal frac_mul_10			: std_logic_vector(13 downto 0);

	--
	-- Display row and column start constants
	--
	constant start_row : std_logic_vector(2 downto 0) := "100"; -- Row 4
	constant start_col : std_logic_vector(4 downto 0) := "00000"; -- begin at 0 for now
	signal char : std_logic_vector(4 downto 0);


begin

	--
	-- Wire up the divider
	--
	div: entity FREQ_DIVIDER
		port map(
		    rfd 		=> divide_rfd,
		    rdy 		=> divide_rdy,
		    nd 			=> divide_nd, 
		    clk 		=> clk,
		    dividend 	=> freq_dividend,
		    quotient 	=> freq_quotient,
		    divisor 	=> freq_divisor,
		    fractional 	=> freq_fractional
		);
	-- New data is the done signal from the autocorrelation unit
	divide_nd <= sample_done;
	-- the divisor is the multiplied value of the bin and the divisor
	--	these values go valid at the same time that done does, and stay
	--	high for at least one clock
	div_x_bin <= std_logic_vector(unsigned(divider) * unsigned(bin));
	freq_divisor <= "0" & div_x_bin;
	-- And the dividend is equal to the system clock speed
	freq_dividend <= std_logic_vector(to_unsigned(sys_clk_spd, freq_dividend'length));


	-- We will need this inside of the process, I can't find a better place for it 
	frac_mul_10 <= std_logic_vector(unsigned(freq_fractional)*to_unsigned(10, 4));

	-- Do the conversion from binary to BCD
	latchDivide: process(clk)
		variable temp_multiply : std_logic_vector(13 downto 0);
	begin
		if (rising_edge(clk)) then
			-- Latch the output of the divider and get ready to begin the
			--	binary-to-bcd conversion
			if ( divide_rdy = '1' ) then 
				latched_quotient 	<= freq_quotient(13 downto 0);
				latched_fractional 	<= freq_fractional;
				convert_val <= (others => '0');
				disp_wr_en  <= '0';
				char 		<= start_col;
				do_convert 	<= '1';

			-- Need 16 clocks to do the conversion of the quotient from binary 
			--	to BCD
			elsif ( (do_convert = '1') and (unsigned(convert_count) < 13) ) then
				-- Need to do all of the conversions. Implement the 
				--	shift-1 and add 3 algorithm. We have 7 digits that
				--	we care about (4 integer and 3 fractional)
				
				-- All digits but the last decimal digit
				convMost: for i in  2 to 4 loop
					if (unsigned(convert_val(4*i - 2 downto 4*i - 5)) >= 5) then
						convert_val(4*i - 1 downto 4*i - 4) <= std_logic_vector(unsigned(convert_val(4*i - 2 downto 4*i - 5)) + 3);
					else
						convert_val(4*i - 1 downto 4*i - 4) <= convert_val(4*i - 2 downto 4*i - 5);
					end if;
				end loop;

				-- Final decimal digit.
				if (unsigned(convert_val(2 downto 0) & latched_quotient(13)) >= 5) then
					convert_val(3 downto 0) <= std_logic_vector(unsigned(convert_val(2 downto 0) & latched_quotient(13)) + 3);
				else
					convert_val(3 downto 0) <= convert_val(2 downto 0) & latched_quotient(13);
				end if;

				-- Need to shift the divide output
				latched_quotient <= latched_quotient(12 downto 0) & "0";

			-- Final convert clock, just shift everything, no add 3 if greater than 5
			elsif ( (do_convert = '1') and (unsigned(convert_count) = 13)) then
				convert_val <= convert_val(14 downto 0) & latched_quotient(13);


			-- Need 8 clocks to write the BCD to the display. The clocks will be used as such:
			--	First 4 clocks: BCD quotient
			--	5th clock: decimal place
			--	Last 3 clocks: Multiply fractional by 10 and take high 4 bits.
			elsif ( (do_convert = '1') and (unsigned(convert_count) >= 14) ) then

				-- Set the write enable on the display FIFO
				disp_wr_en <= '1';

				-- Send out the BCD quotient
				if (unsigned(convert_count) < 18) then 
					-- Output the current convert value and shift the convert value
					disp_data <= start_row & char & X"3" & convert_val(15 downto 12);
					convert_val  <= convert_val(11 downto 0) & "0000";
				-- Send out the decimal place
				elsif (unsigned(convert_count) = 18) then
					-- Output a decimal point and do not shift the convert val
					disp_data <= start_row & char & X"2E";
				-- Send out the decimal
				else
					disp_data <= start_row & char & X"3" & frac_mul_10(13 downto 10);
					latched_fractional <= frac_mul_10(9 downto 0);
				end if;

				-- Always increment the character
				char <= std_logic_vector(unsigned(char) + 1);

			-- And if something is totally wrong just reset everything
			else
				do_convert <= '0';
				convert_count <= (others => '0');
				latched_quotient <= (others => '0');
				latched_fractional <= (others => '0');
				disp_wr_en <= '0';
			end if;

			-- Need to increment the convert clock until we're done
			if (do_convert = '1') then
				if (unsigned(convert_count) = 21) then
					convert_count <= (others => '0');
					do_convert <= '0';
				else
					convert_count <= std_logic_vector(unsigned(convert_count) + 1);
				end if;
			end if;

		end if;

	end process;

end architecture;





















