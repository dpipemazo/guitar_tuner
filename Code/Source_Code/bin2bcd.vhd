--
-- Binary to BCD converter for detected frequency
--
-- The frequency is expected in Q28.4 format
--
-- Take the top 28 bits of the incoming number and use the 
--  shift, add 3 algorithm to convert them to BCD, then
--  take the bottom 4 bits, and repeatedly multiply themby 10
--  and take the integer part to get the final BCD result
--  accurate to 1/16th of frequency. 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.bcdunit;

entity BIN2BCD is 
    
    port(

        -- input clock
        clk     : in std_logic;

        -- input start signal
        start   : in std_logic;

        -- done signal
        done    : out std_logic;

        -- Input 32-bit binary value
        binary_in : in std_logic_vector(31 downto 0);

        -- Output BCD. 13 BCD digits in all
        bcd_out : buffer std_logic_vector(51 downto 0)

    );

end BIN2BCD;

architecture behavioral of BIN2BCD is
    
    -- constant 10 for multiplication by 10 to get decimal out
    constant ten : std_logic_vector(3 downto 0) := "1010";
    signal multiply_result : std_logic_vector(7 downto 0);
    signal multiplicand : std_logic_vector(3 downto 0);

    -- signals to link bcdunits together
    signal bcd_links : std_logic_vector(9 downto 0);
    signal reset : std_logic;
    signal do_shift : std_logic;
    signal do_add : std_logic;

    -- States for the state machine
    type bcd_states is(
        IDLE, 
        INTEGER_BITS_SHIFT, 
        INTEGER_BITS_ADD, 
        INTEGER_BITS_END,
        DECIMAL_BITS_INIT, 
        DECIMAL_BITS_MULTIPLY, 
        DECIMAL_BITS_SHIFT
    );
    signal curr_state : bcd_states;

    -- counters
    signal int_bits_counter : std_logic_vector(5 downto 0);
    signal dec_bits_counter : std_logic_vector(1 downto 0);


begin

    --
    -- Generate the bcdunits for the 9 bcd characters based off of the
    --  top 28 bits of the input binary
    --
    genbcds: for i in 0 to 8 generate
    begin

        bcdunitx: entity BCDUNIT(behavioral)
            port map(
                clk => clk, 
                reset => reset,
                data_in => bcd_links(i),
                data_out => bcd_links(i + 1),
                do_shift => do_shift, 
                do_add => do_add
            );

    end generate genbcds;

    --
    -- The state machine for running the binary to BCD converter
    --
    process(clk)
    begin

        if (rising_edge(clk)) then

            case curr_state is 

                --
                -- If we are in the IDLE state, then 
                --  we need ot initialize variables and 
                --  transfer to the calculation once start 
                --  goes high.
                --
                when IDLE =>

                    -- initialize the shift, add and done signals
                    do_shift <= '0';
                    do_add <= '0';
                    done <= '0';

                    -- Initialize the integer bits counter
                    int_bits_counter <= "001111";

                    if (start = '1') then
                        curr_state <= INTEGER_BITS_SHIFT;
                        reset <= '0';
                    else
                        curr_state <= IDLE;
                        reset <= '1';
                    end if;

                --
                -- Shift everything in the bcdunits left by a bit
                --
                when INTEGER_BITS_SHIFT =>

                    do_shift <= '1';
                    do_add <= '0';

                    -- Put the correct binary on the input shift bus
                    bcd_links(0) <= binary_in(conv_integer(int_bits_counter));

                    -- If we have done 28 shifts then we are done, 
                    -- else move to the add state. Want to shift in bits
                    -- 31 through 4.
                    if (conv_integer(int_bits_counter) = 4) then
                        curr_state <= INTEGER_BITS_END;
                        int_bits_counter <= (others => '0');
                    else
                        curr_state <= INTEGER_BITS_ADD;
                        int_bits_counter <= int_bits_counter - 1;
                    end if;

                --
                -- If any bcdunit is greater than 5, add 3 to it.
                --
                when INTEGER_BITS_ADD =>
                    do_shift <= '0';
                    do_add <= '1';

                    -- After an add, always go back to a shift
                    curr_state <= INTEGER_BITS_SHIFT;

                --
                -- Need to shift all of the values out of the 
                --  bcdunit array. The shift signal is still high
                --  so we just need to get the 36 values out.
                --
                when INTEGER_BITS_END =>

                    bcd_out <= bcd_out(50 downto 0) & bcd_links(9);

                    if (conv_integer(int_bits_counter) = 35) then
                        curr_state <= DECIMAL_BITS_INIT;
                    else
                        curr_state <= INTEGER_BITS_END;
                    end if;
                
                --
                -- Now, the bcd_out has the 36 bits from the 
                --  bcdunits in its lower 36 bits. We need to 
                --  repeat the following process:
                --
                --  1. Take the 4 remaining bits
                --  2. Multiply by 10
                --  3. Shift the top 4 bits of the result into the 
                --      bottom 4 bits of the bcd_out
                --  4. The low 4 bits of the result are
                --      now the remaining 4 bits. 
                --
                when DECIMAL_BITS_INIT =>
                    dec_bits_counter <= (others => '0');
                    multiplicand <= binary_in(3 downto 0);

                    curr_state <= DECIMAL_BITS_MULTIPLY;

                when DECIMAL_BITS_MULTIPLY =>

                    multiply_result <= multiplicand * ten;

                    curr_state <= DECIMAL_BITS_SHIFT;

                when DECIMAL_BITS_SHIFT =>

                    bcd_out <= bcd_out (47 downto 0) & multiply_result(7 downto 4);
                    multiplicand <= multiply_result(3 downto 0);

                    if (conv_integer(dec_bits_counter) = 3) then
                        curr_state <= IDLE;
                        done <= '1';
                    else
                        curr_state <= DECIMAL_BITS_MULTIPLY;
                        dec_bits_counter <= dec_bits_counter + 1;
                    end if;

                when others =>

                    curr_state <= IDLE;

            end case;

        end if;

    end process;

end architecture;

















