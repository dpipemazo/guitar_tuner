--
-- This is a test bench for the frequency conversion module. should
--	be pretty straightforward. 
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.freq_convert;

-- Test bench entity declaration
entity freq_convert_tb is 
end freq_convert_tb;

-- Declare the architecture of the test bench
architecture TB_ARCHITECTURE of freq_convert_tb is
	
	-- The autocorrelation component
	component FREQ_CONVERT is 
		
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

	end component;

	-- Signals to hook up the the conversion unit
	signal test_clk 		: std_logic;
	signal test_divider 	: std_logic_vector(11 downto 0);
	signal test_bin			: std_logic_vector(10 downto 0);
	signal test_sample_done : std_logic;
	signal test_disp_wr_en 	: std_logic;
	signal test_disp_data 	: std_logic_vector(15 downto 0);


begin

	-- Declare the UUT
	UUT: FREQ_CONVERT
		port map(
			clk 		=> test_clk, 		
			divider		=> test_divider,		
			bin			=> test_bin,			
			sample_done => test_sample_done, 
			disp_wr_en	=> test_disp_wr_en,	
			disp_data	=> test_disp_data	
		);

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
    -- Actually test the frequency conversion unit
    -- 
    do_test: process

    	-- Need a random divider and bin
    	variable divider, bin, expected : integer;
    	-- Need seeds for the random generator
    	variable seed1, seed2 : positive;
    	-- Need a real for the random variable
    	variable rand, result_freq : real;
    	-- Loop unti this goes false
    	variable END_SIM : boolean := FALSE;

    begin

    	-- Loop until end sim is no longer valid
    	while (END_SIM = FALSE) loop

            -- Get a random value on the interval [0,1].
            UNIFORM(seed1, seed2, rand);
            -- calculate the expected divider, range [10, 4095]
            divider := integer(round(rand*4085.0 + 10.0));
            -- Get a random value on the interval [0,1].
            UNIFORM(seed1, seed2, rand);
            -- calculate the expected bin, range [1001, 1061]
            bin := integer(round(rand*60.0 + 1001.0));

            --
            -- Calculate the random frequency
            --
            result_freq := 100000000.0/(real(divider)*real(bin));

            --
            -- Put the bin and divider on the line and send the done flag high
            --
            test_divider <= std_logic_vector(to_unsigned(divider, test_divider'length));
            test_bin <= std_logic_vector(to_unsigned(bin, test_bin'length));
            test_sample_done <= '1';

            -- wait for a clock
            wait for 10 ns;

            -- send the sample done signal low
            test_sample_done <= '0';

            -- Wait until test_disp_wr_en goes high
            while (test_disp_wr_en /= '1') loop
            	wait for 5 ns;
            end loop;

            --
            -- Check the thousands digit
            --

            expected := integer(trunc(result_freq/1000.0));
            result_freq := result_freq - real(expected)*1000.0;
            -- Check that the row is 4 and the column is 0 to start with
            assert(test_disp_data(15 downto 13) = "100") report "Thousands digit row invalid";
            assert(test_disp_data(12 downto 8) = "00000")  report "Thousands digit column invalid";
            -- Check that the character is in ASCII form
            assert(test_disp_data(7 downto 4) = "0011") report "Thousands digit not in ASCII format";
            -- Finally, check the digit itself
            assert(to_integer(unsigned(test_disp_data(3 downto 0))) = expected) report "Thousands digit incorrect";

            wait for 10 ns;

            --
            -- Check the Hundreds digit
            --

            expected := integer(trunc(result_freq/100.0));
            result_freq := result_freq - real(expected)*100.0;
            -- Check that the row is 4 and the column is 1
            assert(test_disp_data(15 downto 13) = "100") report "Hundreds digit row invalid";
            assert(test_disp_data(12 downto 8) = "00001")  report "Hundreds digit column invalid";
            -- Check that the character is in ASCII form
            assert(test_disp_data(7 downto 4) = "0011") report "Hundreds digit not in ASCII format";
            -- Finally, check the digit itself
            assert(to_integer(unsigned(test_disp_data(3 downto 0))) = expected) report "Hundreds digit incorrect";

            wait for 10 ns;

            --
            -- Check the Tens digit
            --

            expected := integer(trunc(result_freq/10.0));
            result_freq := result_freq - real(expected)*10.0;
            -- Check that the row is 4 and the column is 2
            assert(test_disp_data(15 downto 13) = "100") report "Tens digit row invalid";
            assert(test_disp_data(12 downto 8) = "00010")  report "Tens digit column invalid";
            -- Check that the character is in ASCII form
            assert(test_disp_data(7 downto 4) = "0011") report "Tens digit not in ASCII format";
            -- Finally, check the digit itself
            assert(to_integer(unsigned(test_disp_data(3 downto 0))) = expected) report "Tens digit incorrect";

            wait for 10 ns;

            --
            -- Check the Ones digit
            --

            expected := integer(trunc(result_freq/1.0));
            result_freq := result_freq - real(expected)*1.0;
            -- Check that the row is 4 and the column is 3
            assert(test_disp_data(15 downto 13) = "100") report "Ones digit row invalid";
            assert(test_disp_data(12 downto 8) = "00011")  report "Ones digit column invalid";
            -- Check that the character is in ASCII form
            assert(test_disp_data(7 downto 4) = "0011") report "Ones digit not in ASCII format";
            -- Finally, check the digit itself
            assert(to_integer(unsigned(test_disp_data(3 downto 0))) = expected) report "Ones digit incorrect";

            wait for 10 ns;

            --
            -- Check the decimal place
            --

            -- Check that the row is 4 and the column is 4
            assert(test_disp_data(15 downto 13) = "100") report "Decimal place row invalid";
            assert(test_disp_data(12 downto 8) = "00100")  report "Decimal place column invalid";
            -- Check the decimal
            assert(test_disp_data(7 downto 0) = X"2E") report "Decimal point incorrect";

            wait for 10 ns;

            --
            -- Check the tenths digit
            --

            expected := integer(trunc(result_freq/0.1));
            result_freq := result_freq - real(expected)*0.1;
            -- Check that the row is 4 and the column is 3
            assert(test_disp_data(15 downto 13) = "100") report "Tenths digit row invalid";
            assert(test_disp_data(12 downto 8) = "00101")  report "Tenths digit column invalid";
            -- Check that the character is in ASCII form
            assert(test_disp_data(7 downto 4) = "0011") report "Tenths digit not in ASCII format";
            -- Finally, check the digit itself
            assert(to_integer(unsigned(test_disp_data(3 downto 0))) = expected) report "Tenths digit incorrect";

            wait for 10 ns;

            --
            -- Check the hundredths digit
            --

            expected := integer(trunc(result_freq/0.01));
            result_freq := result_freq - real(expected)*0.01;
            -- Check that the row is 4 and the column is 3
            assert(test_disp_data(15 downto 13) = "100") report "Hundredths digit row invalid";
            assert(test_disp_data(12 downto 8) = "00110")  report "Hundredths digit column invalid";
            -- Check that the character is in ASCII form
            assert(test_disp_data(7 downto 4) = "0011") report "Hundredths digit not in ASCII format";
            -- Finally, check the digit itself
            assert(to_integer(unsigned(test_disp_data(3 downto 0))) = expected) report "Hundredths digit incorrect";

            wait for 10 ns;

            --
            -- Finally, check the thousandths digit
            --

            expected := integer(trunc(result_freq/0.001));
            -- Check that the row is 4 and the column is 3
            assert(test_disp_data(15 downto 13) = "100") report "Thousandths digit row invalid";
            assert(test_disp_data(12 downto 8) = "00111")  report "Thousandths digit column invalid";
            -- Check that the character is in ASCII form
            assert(test_disp_data(7 downto 4) = "0011") report "Thousandths digit not in ASCII format";
            -- Finally, check the digit itself
            assert(to_integer(unsigned(test_disp_data(3 downto 0))) = expected) report "Thousandths digit incorrect";

            wait for 15 ns;

        end loop;

    end process;

end architecture;



