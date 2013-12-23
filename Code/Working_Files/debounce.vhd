--
-- This is a unit which debounces the pushbuttons on the Xilinx 
--	Spartan 6 FPGA which is being used in the guitar tuner
--
-- It takes a std_logic_vector of buttons as input and 
--	returns broken out std_logic, active-high signals.
--	All debounced buttons will be active-high!
--
-- The hardware description of the input buttons can be found 
--	in the .ucf file, but can be found here as well
--
--	Button 0: 	Reset	 	Active Low
--	Button 1: 	Up			Active High
--	Button 2: 	Left		Active High
--	Button 3: 	Down		Active High
--	Button 4: 	Right		Active High
--	Button 5: 	Center		Active High
--
--	Each button will have its own debounce logic. It will be 
--	considered debounced after being down for somewhere around 10ms. The keys will then
--	auto-repeat to throw multiple key events

--
-- Libraries
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

--
--
---
----
----- SINGLE DEBOUNCER CODE
----
---
--
--

--
-- This is the code for the single-key debouncer. The large 
--	debouncer will be made up of as many of these as necessary
--	or desired
--

-- Declare the I/O
entity SINGLE_DEBOUNCE is
	
	-- Control over debounce and auto-repeat time. Number
	--	given is number of debounce clocks to wait for 
	--	the named event to happen. Valid range is [1, 1023]
	generic (
        debounce_clocks : integer := 20;     -- clocks to wait for debounce
        auto_rep_clocks : integer := 600    -- clocks to wait for auto-repeat
    );

	-- Signals 
	port (

		-- Inputs
		debounce_clock 	: in std_logic;	-- Debounce clock, 1KHz. 
		button_in		: in std_logic; -- Raw button input

		-- Ouputs
		debounced_out	: out std_logic -- Debounced output. High
										--	for a single debounce clock
										-- 	every time that a debounce event is to 
										--	be thrown. 
	);

end SINGLE_DEBOUNCE;

--
-- First, need to synchronize the button input. So DFF it twice. 
--
-- Use an internal 9-bit counter to count. On every clock edge for which
--	input button is down, increment the counter. When a key event is thrown, 
--	reset the counter. 
--
-- Initially, set the compare on the counter to DEBOUNCE_TIME, which 
--	should be somewhere on the order of tens of clocks, since the 
--	debounce clock is running at 1.5KHz. Once the key has been 
--	debounced, set the compare to something on the order of hundreds of 
--	clocks in order to auto-repeat at a reasonable rate. 
architecture behavioral of SINGLE_DEBOUNCE is 
	
	-- Synchronization signals
	signal sync_1	: std_logic; -- First synchronization DFF
	signal sync_2	: std_logic; -- Second synchronization DFF

	-- Debounce counter
	signal debounce_counter		: std_logic_vector(9 downto 0);

	-- Debounce compare register
	signal debounce_compare		 : std_logic_vector(9 downto 0);

begin

	-- Synchronize the inputs and DFF the muxes. 
	doDFF: process(debounce_clock)
	begin

		if (rising_edge(debounce_clock)) then

			-- Synchronize the buttons
			sync_1 <= button_in;
			sync_2 <= sync_1;

			-- If the button is high
			if (sync_2 = '1') then
				-- If the counter has reached the compare
				if (std_match(debounce_counter, debounce_compare)) then
					-- Reset the counter and set the compare to auto-repeat
					debounce_counter <= (others => '0');
					debounce_compare <= std_logic_vector(to_unsigned(auto_rep_clocks, debounce_compare'length));
					-- Set the output high
					debounced_out <= '1';
				else
					-- Just increment the counter and reset the debounced output
					debounce_counter <= std_logic_vector(unsigned(debounce_counter) + 1);
					debounced_out <= '0';
				end if;

			-- If the button is low
			else
				-- reset the compare to the debounce clocks and reset the counter
				debounce_compare <= std_logic_vector(to_unsigned(debounce_clocks, debounce_compare'length));
				debounce_counter <= (others => '0');
			end if;

		end if;

	end process;

end architecture;		

--
--
---
----
----- FULL DEBOUNCER CODE
----
---
--
--

--
-- Libraries
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

--
-- Declare the I/O. 
--
entity DEBOUNCE is
	
	port(
		-- Inputs
		clock		: in std_logic;						-- system clock, 100MHz
		buttons		: in std_logic_vector(5 downto 0);	-- Raw button lines

		-- Outputs
		button_0	: out std_logic; -- Active High. RESET
		button_1	: out std_logic; -- Active High. UP
		button_2	: out std_logic; -- Active High. LEFT
		button_3	: out std_logic; -- Active High. DOWN
		button_4	: out std_logic; -- Active High. RIGHT
		button_5	: out std_logic  -- Active High. CENTER
	);

end DEBOUNCE;

--
-- We will use as many of the SINGLE_DEBOUNCE units as we desire
--	to perform our debouncing. These units will take a number of
--	debounce clocks and auto-repeat clocks and will generate
--	an active-high signal for one debounce clock if the key has been debounced
--	
-- We also need to generate a debounce clock. This clock should be
--	on the order of 1KHz. Since we are assuming that our input clock is 
--	100MHz, we need to use a counter in order to generate the appropriate 
--	pulses. In order to make this easy, we will just use a 16-bit counter, 
--	and have the high bit be the clock signal. This will create a ~1.5KHz
--	clock which is good enough. 
--
--	We also need to be careful to invert the reset button before
-- 	feeding it into the debounce unit, since it is active low and 
--	our debounce units assume active high input and produce active high
--	output
--
architecture behavioral of DEBOUNCE is 
	
	-- Need signals for I/O of single debounce units
	signal db_ins 	: std_logic_vector(5 downto 0);
	signal db_outs	: std_logic_vector(5 downto 0);

	-- Need a counter for the debounce clock
	signal db_clock_counter : std_logic_vector(15 downto 0);

	-- Need the actual debounce clock
	signal db_clock : std_logic;
   	attribute buffer_type : string;
	attribute buffer_type of db_clock : signal is "BUFG";

	-- Need to declare the SINGLE_DEBOUNCE component
	component SINGLE_DEBOUNCE

		port (

			-- Inputs
			debounce_clock 	: in std_logic;	-- Debounce clock, 1KHz. 
			button_in		: in std_logic; -- Raw button input

			-- Ouputs
			debounced_out	: out std_logic -- Debounced output. High
											--	for a single debounce clock
											-- 	every time that a debounce event is to 
											--	be thrown. 
		);

	end component;

begin

	-- Generate each of the single debounce units
	genDBs: for i in 0 to 5 generate
	begin

		DBx: SINGLE_DEBOUNCE
			port map(
				debounce_clock 	=> db_clock,
				button_in 		=> db_ins(i),
				debounced_out 	=> db_outs(i)
			);

	end generate genDBs;

	-- Now, need to map the inputs for the debounce units
	db_ins(5 downto 1) 	<= buttons(5 downto 1); -- Map all of the active high buttons
	db_ins(0) 			<= not buttons(0);		-- Map the active low reset

	-- And map the outputs
	button_0  <= db_outs(0);
	button_1  <= db_outs(1);
	button_2  <= db_outs(2);
	button_3  <= db_outs(3);
	button_4  <= db_outs(4);
	button_5  <= db_outs(5);

	-- Need to increment the debounce clock counter every clock
	doDFF: process(clock)
	begin

		if (rising_edge(clock)) then

			-- Every clock, increment the debounce clock counter 
			db_clock_counter <= std_logic_vector(unsigned(db_clock_counter) + 1);

			-- Assign the debounce clock to the high bit of the debounce clock counter
			db_clock <= db_clock_counter(15);

		end if;

	end process;

end architecture;




