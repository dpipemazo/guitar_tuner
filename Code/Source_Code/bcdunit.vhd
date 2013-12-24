--
-- BCDUNIT
--  This is a simple unit for converting binary to BCD which will perform the 
--  shift, add 3 algorithm on 4 bits. You can string as many of these together
--  as desired to compute BCD values as big as you want
--
-- Use 1 BCD unit per digit of output which you want

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

entity BCDUNIT is 
    
    port(
        clk         : in std_logic;
        reset       : in std_logic;

        data_in     : in std_logic;
        data_out    : out std_logic;

        do_shift    : in std_logic;
        do_add      : in std_logic
    );

end BCDUNIT;

architecture behavioral of BCDUNIT is
    
    -- Internal 4-bit BCD value
    signal bcd: std_logic_vector(3 downto 0);

begin

    -- Data out is always the top bit of the BCD
    data_out <= bcd(3);

    -- Our logic
    process(clk)
    begin

        -- Only do stuff on clock rising edges
        if (rising_edge(clk)) then

            -- On reset, reset the internalized value to 0
            if (reset = '1') then
                bcd <= (others => '0');

            -- Else, not reset
            else
                -- If we are doing a shift, then shift in data
                if(do_shift = '1') then
                    bcd <= bcd(2 downto 0) & data_in;
                -- If we are not doing a shift
                else
                    -- If we are doing an add, and the value of BCD is >= 5,
                    if(do_add = '1' and conv_integer(bcd) >= 5) then
                        bcd <= bcd + 3;
                    end if;

                end if;

            end if;

        end if;

    end process;

end architecture;





