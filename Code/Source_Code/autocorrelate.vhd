--
-- This is the VHDL file for an autocorrelation unit
-- It will perform autocorrelation for a single value, 
-- with the result on the output bus. These can be wired 
-- up fairly simply, acting as shift registers and autocorrelaters.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

-- the actual entity
entity autocorrelation is
    
    port(

        -- system clock
        clk     : in std_logic;

        -- signal to start autocorrelation
        do_auto : in std_logic;

        -- signal to load in a new static autocorrelation value
        do_load : in std_logic;

        -- signal to reset
        reset   : in std_logic;

        -- The sample which we will be computing the 
        --  autocorrelation against. These will be the
        --  samples shifting in and out.
        sample_in  : in std_logic_vector(1 downto 0);

        -- The autocorrelation output
        result : out std_logic_vector(15 downto 0)

    );
end autocorrelation;

-- Now define the architecture
architecture behavioral of autocorrelation is 

    -- Static sample
    signal auto_sample : std_logic_vector(1 downto 0);

    -- the autocorrelation result
    signal auto_sum : std_logic_vector(15 downto 0);

begin

    -- Always have the current result on the output bus
    result <= auto_sum;

    --
    -- Do the autocorrelation computation
    --
    process(clk)
    begin
        if (rising_edge(clk)) then
            -- If we want to reset the autocorrelation values
            if (reset = '1') then
                auto_sum <= (others => '0');

            -- If we are doing autocorrelation
            else
                if (do_auto = '1') then

                    -- Take care of incrementing/decrementing the 
                    --  autocorrelation value
                    --
                    -- If both bottom bits are set, then we are either adding
                    --  or subtracting one.
                    if ((auto_sample(0) and sample_in(0)) = '1') then
                        -- If only one top bit is set then we subtract
                        if ((auto_sample(1) xor sample_in(1)) = '1') then
                            auto_sum <= auto_sum - 1;
                        -- else we add
                        else
                            auto_sum <= auto_sum + 1;
                        end if;
                    end if;
                end if;

                -- Else if we are loading data
                if (do_load = '1') then
                    auto_sample <= sample_in;
                end if;
                
            end if;

        end if;

    end process;


end architecture;





