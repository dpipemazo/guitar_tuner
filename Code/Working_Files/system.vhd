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
use work.autocorrelation;


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
        sw          : in  std_logic_vector(7 downto 0)

    );
end system;

architecture structural of system is 

    -- Individual button signals
    signal db_buttons   : std_logic_vector(5 downto 0);

    -- Samples from the audio unit
    signal sample       : std_logic_vector(1 downto 0);
    signal sample_valid : std_logic;

    -- Sample to output to the DAC
    signal output_sample : std_logic_vector(18 downto 0);
    -- Sample coming in from the ADC
    signal input_sample  : std_logic_vector(18 downto 0);

    -- signals controlling playback
    signal play_samples  : std_logic; -- active high to play samples
    signal play_output   : std_logic; -- 1 = line out, 0 = headphones

    -- Autocorrelation results
    signal auto_result_div : std_logic_vector(11 downto 0);
    signal auto_result_idx : std_logic_vector(10 downto 0);
    signal auto_done       : std_logic;

    -- 

begin

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
            n_reset         => not db_buttons(0),
            2_bit_sample    => sample,
            sample_valid    => sample_valid,
            raw_sample_out  => output_sample,
            raw_sample_in   => input_sample,
            play_samples    => play_samples,
            play_output     => play_output
        );

    corr: entity AUTOCORRELATE
        port map(
            clock       => clk,
            sample      => sample,
            reset       => db_buttons(0) or (not sample_valid),
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
    led(0) <= sample_valid;
    -- Output the sample itself onto the next 2 LEDs
    led(2 downto 1) <= sample(1 downto 0);

end structural;
