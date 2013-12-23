--
-- Clock divider for EE119c digital guitar tuner project
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

-- The clock divider entity
entity CLOCKDIV is
    port(

        -- input clock, 100MHZ
        clk_100mhz      : in std_logic;

        -- Output clocks at 400KHz, 200KHz and 100KHz
        clk_400khz      : out std_logic;
        clk_200khz      : out std_logic;
        clk_100khz      : out std_logic

    );
end CLOCKDIV;

-- And just divide some clocks
architecture behavioral of CLOCKDIV is
   
   -- Our counter, want it to count to 1023 so that we can divide our 
   --   100MHz clock down by 1023 to get a roughly 100KHz sample clock.
   signal clk_div_counter : std_logic_vector(9 downto 0);
   signal clk_div_result  : std_logic_vector(9 downto 0);

   -- Declare the buffer_type itself
   attribute buffer_type : string;

   -- Make these clock signals be clock buffered
   attribute buffer_type of clk_400khz : signal is "BUFG";
   attribute buffer_type of clk_200khz : signal is "BUFG";
   attribute buffer_type of clk_100khz : signal is "BUFG";

begin

    --
    -- Do the incrementing asynchronously and latching synchronously to
    --  eliminate skew
    --
    clk_div_result <= clk_div_counter + 1;

    --
    -- Latch the new clk_div_counter and clocks
    --  on rising edges of the system clock
    --
    process(clk_100mhz)
    begin

        if (rising_edge(clk_100mhz)) then

            -- Latch the new result into the counter
            clk_div_counter <= clk_div_result;

            -- Use bit 9 to divide by 1024 and create the 100khz clock
            clk_100khz <= clk_div_result(9);

            -- Use bit 8 to divide by 512 and create the 200khz clock
            clk_200khz <= clk_div_result(8);

            -- Use bit 7 to divide by 256 and create the 400KHz clock
            clk_400khz <= clk_div_result(7);

        end if;
    end process;

end architecture;

