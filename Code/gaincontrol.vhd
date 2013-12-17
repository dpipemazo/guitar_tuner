--
-- This unit implements gain control for the pitch detector
--  through control of a 1024-tap, 0-50k digital potentiometer
--  hooked up in a simple noninverting op-amp configuration
--  which is used to control the overall gain on the input
--  audio signal. 
-- This code is meant to be used with the AD5231 over an 
--  SPI protocol
--
-- The general calculation will be:
--
--  new_pot_val = (num_samples * old_pot_val)/(num_samples + gain_distance)
--
-- Since this increases the gain to the distance implied by the threshold. Always
--  give gain differences with respect to the upper threshold, since the signal
--  intensity can only die out with time, not grow. 
--
-- NOTE: want to use CPOL = 0
-- Another note: shouldn't have a problem with acknowledge since
--  this process will be called sparsely compared to the difference
--  in clock domains. But may need to add an "ack" to the wait
--  loop in the sampling scheme

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

-- The actual entity
entity GAINCONTROL is 
    
    generic(
        num_samples : std_logic_vector(12 downto 0) := "1010000000000"
    );

    port(

        -- potentiometer signals
        pot_cs      : out std_logic;
        pot_data    : out std_logic;
        pot_clk     : out std_logic;

        -- system clock
        --  CANNOT BE FASTER THAN 50 MHZ. SHOULD REALLY
        --  BE SOMETHING LIKE 25 MHZ
        clk     : in std_logic;

        -- start/done signals
        start   : in std_logic;
        done    : out std_logic;
        reset   : in std_logic;

        -- Whether to increase ordecrease the gain
        --  1 == increase gain
        --  0 == decrease gain
        inc_dec : in std_logic;

        -- How much the signal is off by
        gain_diff : in std_logic_vector(12 downto 0)
    );

end GAINCONTROL;

-- Make the entity bend to my will
architecture behavioral of GAINCONTROL is
    
    -- divider
    component gaincontrol_div
        port (
            clk: in std_logic;
            nd: in std_logic;
            rdy: out std_logic;
            rfd: out std_logic;
            dividend: in std_logic_vector(22 downto 0);
            divisor: in std_logic_vector(22 downto 0);
            quotient: out std_logic_vector(22 downto 0);
            fractional: out std_logic_vector(22 downto 0)
        );
    end component;



    -- state machine
    type gain_states is(
        IDLE,
        RESET_STATE,
        DIVIDE,
        SET_NEW_POT_VAL, 
        SEND_NEW_POT_VAL_LOW, 
        SEND_NEW_POT_VAL_HIGH,
        DONE_STATE 
    );
    signal curr_state : gain_states;

    -- AD5231 write to RDAC regtser command byte
    constant write_command : std_logic_vector(7 downto 0) := "10110000";

    -- Current resistance value (range 0 - 1023, as a percentage out
    --  of 1023 times 50k)
    signal  curr_pot : std_logic_vector(9 downto 0);

    -- Math results (23 bits in order to cover 5120 * 1024)
    signal numerator_result : std_logic_vector(22 downto 0);
    signal divisor : std_logic_vector(22 downto 0);
    signal denominator_add_result : std_logic_vector(12 downto 0);
    signal denominator_sub_result : std_logic_vector(12 downto 0);
    signal denominator_result : std_logic_vector(12 downto 0);
    signal divide_result : std_logic_vector(22 downto 0);

    signal new_pot_result : std_logic_vector(9 downto 0);

    --
    -- Signals for sending the new potentiometer command
    --
    signal command_to_send : std_logic_vector(23 downto 0);
    signal send_count : std_logic_vector(4 downto 0);
    constant command_length : std_logic_vector(4 downto 0) := "10111";
    constant reset_max_command : std_logic_vector(23 downto 0) := "101100000000001111111111";

    -- Signal for doing reset cycle
    signal do_reset : std_logic;

    -- Divider signals
    signal div_new_data : std_logic;
    signal div_rdy : std_logic;



begin

    --
    -- Calculate the new numerator
    --
    numerator_result <= num_samples * curr_pot;

    --
    -- Calculate the new denominator (will either need to be an add/subract based on
    --  whether trying to increase or decrease gain)
    --
    denominator_add_result <= num_samples + gain_diff;
    denominator_sub_result <= num_samples - gain_diff;

    -- If we are trying to increase the gain (1) then use the add result, else use
    --  the subtract result.
    denominator_result <=   denominator_add_result when (inc_dec = '1') else
                            denominator_sub_result;


    -- Set the new potentiometer to the low 10 bits of the divide result if no overflow otu of 10 bits, 
    --  else set it to the max and hope that it works.
    new_pot_result <=   divide_result(9 downto 0) when (OR_REDUCE(divide_result(22 downto 10)) = '0') else
                        (others => '1');


    --
    -- New command to send (24 bits, first 8 are the command, next 6 are blank, next 10 are pot value)
    --
    command_to_send <=  write_command & "000000" & curr_pot when (do_reset = '0') else
                        reset_max_command;

    --
    -- Throw together the little state machine
    --
    process(clk)
    begin

        if (rising_edge(clk)) then

            case curr_state is

                --
                -- When we're in the IDLE state just wait for
                --   the start signal
                --
                when IDLE =>

                    -- Reset CS and clock
                    pot_cs <= '1';
                    pot_clk <= '0';
                    done <= '0';

                    if (reset = '1') then
                        curr_state <= RESET_STATE;
                        do_reset <= '1';
                    else
                        if (start = '1') then
                            div_new_data <= '1';
                            curr_state <= DIVIDE;
                            do_reset <= '0';
                        else
                            curr_state <= IDLE;
                            do_reset <= '0';
                        end if;
                    end if;


                --
                -- Wait for the divider to be done, since 
                --  it has an inherent latency which 
                --  we want to leave to be variable
                --
                when DIVIDE =>
                    if (div_rdy = '1') then 
                        curr_state <= SET_NEW_POT_VAL;
                    else
                        curr_state <= DIVIDE;
                    end if;

                --
                -- Send the new potentiometer value to the 
                -- controller. We might need to pipeline the 
                --  divide process a bit to fix time lag.
                --
                when SET_NEW_POT_VAL =>

                    -- Set the new potentiometer value
                    curr_pot <= new_pot_result;
                    -- Get ready to send data
                    send_count <= command_length;
                    pot_clk <= '0';
                    pot_cs <= '0';

                    -- And begin to send data
                    curr_state <= SEND_NEW_POT_VAL_LOW;

                when SEND_NEW_POT_VAL_LOW =>
                    -- put the new data on the line
                    pot_data <= command_to_send(conv_integer(send_count));
                    -- Send the clock low
                    pot_clk <= '0';
                    
                    curr_state <= SEND_NEW_POT_VAL_HIGH;

                when SEND_NEW_POT_VAL_HIGH =>
                    --send the clock high
                    pot_clk <= '1';

                    -- Asses what to do based on the current 
                    --  send count
                    if (conv_integer(send_count) = 0) then
                        curr_state <= DONE_STATE;
                    else
                        send_count <= send_count - 1;
                        curr_state <= SEND_NEW_POT_VAL_LOW;
                    end if;

                when DONE_STATE =>
                    done <= '1';
                    curr_state <= IDLE;

                when RESET_STATE =>
                    -- we reset to the maximum pot value/minimum gain
                    curr_pot <= (others => '1');
                    -- Get the chiop select and clock low in prep
                    pot_clk <= '0';
                    pot_cs <= '0';

                    -- Send the new pot value
                    curr_state <= SEND_NEW_POT_VAL_LOW;
            end case;

        end if;

    end process;

    --
    -- Instantiate the divider
    --
    divisor <= "0000000000" & denominator_result;

    gaindiv : gaincontrol_div
        port map (
            clk => clk,
            nd => div_new_data,
            rdy => div_rdy,
            dividend => numerator_result,
            divisor => divisor,
            quotient => divide_result
        );

end architecture;














