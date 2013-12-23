--
-- System-level VHDL setup
--
-- Currently just testing the ac97 driver, button debouncing
--  and autocorrelation algorithm. 
--
--
-- All this system should do at the moment:
--  1. Grab samples from codec
--  2. Threshold samples based on max/min
--  3. Feed samples to autocorrelation
--  4. Get divider and index result from autocorrelation
--  5. Light up some LEDs based on however debugging is currently planned.

library work;
use work.audio;
use work.debounce;
use work.autocorrelate;


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

-- Entity declaration
entity system is 
    
    port(

        -- system clock
        clk         : in  std_logic;

        -- pushbuttons
        btn         : in  std_logic_vector(5 downto 0);
        -- leds
        led         : out std_logic_vector(7 downto 0);
        -- switches
        sw          : in  std_logic_vector(7 downto 0);

        -- Need to declare I/O for audio here
        AUDSDI          : in std_logic;
        AUDSDO          : out std_logic;
        AUDSYNC         : out std_logic;
        AUDRST          : out std_logic;
        BITCLK          : in std_logic

    );
end system;

architecture structural of system is 

    -- Individual button signals
    signal db_buttons   : std_logic_vector(5 downto 0);
    signal button_latch : std_logic_vector(5 downto 0);
    signal curr_button  : std_logic_vector(5 downto 0);
    signal button_count : std_logic_vector(1 downto 0);


    -- Samples from the audio unit
    signal sample       : std_logic_vector(1 downto 0);
    signal sample_valid : std_logic;

    -- Sample to output to the DAC
    signal output_sample : std_logic_vector(17 downto 0);
    -- Sample coming in from the ADC
    signal input_sample  : std_logic_vector(17 downto 0);

    -- signals controlling playback
    signal play_samples  : std_logic; -- active high to play samples
    signal play_output   : std_logic; -- 1 = line out, 0 = headphones

    -- Autocorrelation results
    signal auto_result_div : std_logic_vector(11 downto 0);
    signal auto_result_idx : std_logic_vector(10 downto 0);
    signal auto_done       : std_logic;

    -- Resets
    signal auto_reset  :  std_logic;

begin

    --
    -- Various reset logic
    --
    auto_reset <= not btn(0);

    --
    -- The button debouncing unit
    --
    dbounce: entity DEBOUNCE
    
        port map(
            clock       => clk,
            buttons     => btn,
            button_0    => db_buttons(0),
            button_1    => db_buttons(1),
            button_2    => db_buttons(2),
            button_3    => db_buttons(3),
            button_4    => db_buttons(4),
            button_5    => db_buttons(5)
        );

    --
    -- The audio processing unit
    --
    audo: entity AUDIO
        port map(
            clock           => clk,
            n_reset         => btn(0),
            auto_sample     => sample,
            sample_valid    => sample_valid,
            raw_sample_out  => output_sample,
            raw_sample_in   => input_sample,
            play_samples    => play_samples,
            play_output     => play_output,
            audsdi          => AUDSDI,  
            audsdo          => AUDSDO,  
            sync            => AUDSYNC,  
            audrst          => AUDRST,  
            bitclk          => BITCLK 
        );

    corr: entity AUTOCORRELATE
        port map(
            clock       => clk,
            sample      => sample,
            reset       => auto_reset,
            result_div  => auto_result_div,
            result_idx  => auto_result_idx,
            done        => auto_done
                                                            
        );

    --
    -- Map the input samples right back to the output samples, 
    --  to do loopback if we want to try to get that working.
    --
    output_sample <= input_sample;
    -- Play the looped back audio with switch 0
    play_samples <= sw(0);
    -- Choose the play output with switch 1
    play_output <= sw(1);

    --
    -- Now, light up some LEDs with some status info
    --

    -- Output the valid sample onto the bottom LED
    -- led(0) <= sample_valid;
    -- Output the sample itself onto the next 2 LEDs
    -- led(2 downto 1) <= sample(1 downto 0);

    --
    -- Make sure that the button debouncing is working
    --
    doButton : process(clk)
    begin

        if (rising_edge(clk)) then

            -- Latch the buttons to catch a rising edge
            button_latch <= db_buttons;

            -- If we got a rising edge on a new button
            if (not std_match(button_latch, db_buttons)) then

                if (std_match(curr_button, (button_latch xor db_buttons))) then

                    button_count <= std_logic_vector(unsigned(button_count) + 1);
                else
                    curr_button <= button_latch xor db_buttons;
                    button_count <= "01";
                end if;
            else
                button_count <= "00";
            end if;
        end if;

    end process;

    --
    -- Output the current button in the high 3 bits of the LEDs and the 
    --  count in 5 to 4
    --
    --led(7 downto 5) <=  "001" when std_match(curr_button, "000001") else
                        -- "010" when std_match(curr_button, "000010") else
                        -- "011" when std_match(curr_button, "000100") else
                        -- "100" when std_match(curr_button, "001000") else
                        -- "101" when std_match(curr_button, "010000") else
                        -- "110" when std_match(curr_button, "100000") else
                        -- "111" when (not std_match(curr_button, "000000")) else
                        -- "000";

    --led(4 downto 3) <= button_count;

    -- Put the raw samples onto the LED to get sign of life
    led(5 downto 0) <= btn(5 downto 0);



end structural;
