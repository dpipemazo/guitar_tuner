--
-- System-level VHDL setup
--
-- The system currently 
--  takes in samples from the ac97 driver, 
--  passes them through min/max thresholding, 
--  passes the 2-bit samples onto autocorrelation
--  which will then send them to be converted into
--  base 10 and will be put on the display.

library work;
use work.audio;
use work.debounce;
use work.autocorrelate;
use work.display;
use work.user_interface;
use work.freq_convert;
use work.tuner;


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
        reset_unsync: in  std_logic;
        btn         : in  std_logic_vector(4 downto 0);
        -- leds
        led         : out std_logic_vector(7 downto 0);
        -- switches
        source      : in  std_logic;
        volume      : in  std_logic_vector(4 downto 0);
        m0_sw       : in  std_logic;
        m1_sw       : in  std_logic;

        -- Need to declare I/O for audio here
        AUDSDI          : in std_logic;
        AUDSDO          : out std_logic;
        AUDSYNC         : out std_logic;
        AUDRST          : out std_logic;
        BITCLK          : in std_logic;

        -- Need Display I/O as well
        lcd_rs      : out std_logic;
        lcd_rw      : out std_logic;
        lcd_e       : out std_logic;
        lcd_data    : out std_logic_vector(7 downto 0);

        -- Stepper motor I/O
        motor_step          : out std_logic;
        motor_dir           : out std_logic;
        n_step_en           : out std_logic;
        motor_m0            : out std_logic;
        motor_m1            : out std_logic

    );
end system;

architecture structural of system is 

    -- Debounced buttons
    signal db_buttons   : std_logic_vector(4 downto 0);

    -- Signals for the display
    signal disp_wr_en        : std_logic;
    signal disp_data         : std_logic_vector(15 downto 0);
    signal disp_fifo_full    : std_logic;
    signal disp_fifo_empty   : std_logic;

    -- Signals to hook up the audio unit to the autocorrelation unit
    signal sample           : std_logic_vector(1 downto 0);
    signal sample_valid     : std_logic;

    -- Signals to hook up the autocorrelation unit to the 
    --  conversion unit
    signal auto_result_div  : std_logic_vector(11 downto 0);
    signal auto_result_idx  : std_logic_vector(10 downto 0);
    signal auto_done        : std_logic;

    -- Signals for the frequency conversion unit to talk to 
    --  the display
    signal freq_convert_data    : std_logic_vector(15 downto 0);
    signal freq_convert_wr_en   : std_logic;
    signal sample_done_sig      : std_logic;
    signal freq_quot            : std_logic_vector(13 downto 0);
    signal freq_frac            : std_logic_vector(9 downto 0);

    -- Signals for the user interface unit to talk to the display
    signal ui_wr_en         : std_logic;
    signal ui_data          : std_logic_vector(15 downto 0);

    -- Need to syhcnronize the reset button into our circuit
    signal reset_sync       : std_logic;
    signal n_reset          : std_logic;

    -- Signals for the controls coming from the user interface unit
    signal run_motors           : std_logic;
    signal curr_string          : std_logic_vector(2 downto 0);

    -- Signals for the tuner unit
    signal new_tune_freq        : std_logic;
    signal step                 : std_logic;
    signal dir                  : std_logic;
    signal tuned                : std_logic;
    signal n_stepping           : std_logic;

    signal auto_reset          : std_logic;

begin

    --
    -- Display Unit
    --
    dsply: entity DISPLAY
        port map(
                    
            clk             => clk,
            lcd_rs          => lcd_rs,
            lcd_rw          => lcd_rw,
            lcd_e           => lcd_e,
            lcd_data        => lcd_data,
            fifo_wr_en      => disp_wr_en,
            fifo_wr_data    => disp_data,
            fifo_full       => disp_fifo_full,
            fifo_empty      => disp_fifo_empty,
            n_reset         => n_reset
        );

    --
    -- Button Debouncer
    --
    dbounce: entity DEBOUNCE
        port map(
            clk         => clk,
            buttons     => btn,
            db_buttons  => db_buttons
        );

    --
    -- The audio processing unit
    --
    audo: entity AUDIO
        port map(
            clk             => clk,
            n_reset         => n_reset,
            auto_sample     => sample,
            sample_valid    => sample_valid,
            audsdi          => AUDSDI,  
            audsdo          => AUDSDO,  
            sync            => AUDSYNC,  
            audrst          => AUDRST,  
            bitclk          => BITCLK,
            source          => source,
            volume          => volume 
        );

    --
    -- The autocorrelation unit
    --

    corr: entity AUTOCORRELATE
        port map(
            clk         => clk,
            sample      => sample,
            n_reset     => auto_reset,
            result_div  => auto_result_div,
            result_idx  => auto_result_idx,
            done        => auto_done,
            curr_string => curr_string,
            tuned       => tuned                                               
        );

    -- Want to reset the autocorrelation unit if we either
    --  get the reset signal or we are currently stepping
    --  or if the sample is not valid
    auto_reset <= n_reset and n_stepping and sample_valid;

    --
    -- The frequency conversion unit. Takes an index and
    --  divider from the autocorrelation unit
    --  and puts the decimal form on the display
    --
    frqconv : entity FREQ_CONVERT
        port map(
            clk             => clk,
            divider         => auto_result_div,
            bin             => auto_result_idx,
            sample_done     => sample_done_sig,
            disp_wr_en      => freq_convert_wr_en,
            disp_data       => freq_convert_data,
            quot_out        => freq_quot,
            frac_out        => freq_frac,
            new_freq        => new_tune_freq

        );

    --
    -- The user interface unit
    --
    uiunit : entity USER_INTERFACE
        port map(
            clk                 => clk,
            n_reset             => n_reset,
            db_buttons          => db_buttons,
            disp_wr_en          => ui_wr_en,
            disp_data           => ui_data, 
            disp_fifo_full      => disp_fifo_full,
            current_string      => curr_string,
            run_auto_tune       => run_motors,
            tuned               => tuned
        );

    --
    -- And the tuner unit
    --
    tunr : entity TUNER
        port map(
            clk             => clk,
            n_reset         => n_reset,
            run_motor       => run_motors,
            curr_string     => curr_string, 
            div_quotient    => freq_quot,
            div_fractional  => freq_frac,
            new_data        => new_tune_freq,
            step            => step,
            dir             => dir,
            tuned           => tuned,
            n_stepping      => n_stepping

        );

    --
    -- Assign the stepper motor signals
    --
    motor_step  <= step;
    motor_dir   <= dir;
    n_step_en   <= not run_motors;
    motor_m0    <= m0_sw; -- eighth-step microstepping
    motor_m1    <= m1_sw;

    --
    -- Need to set up a multiplexer for the FIFO data. Priority
    --  is given to the frequency unit. This may cause us to
    --  miss a button every now and then. But there are 
    --  worse things in the world
    --
    disp_data   <=  freq_convert_data when (freq_convert_wr_en = '1') else
                    ui_data;

    disp_wr_en  <= (freq_convert_wr_en or ui_wr_en);

    --
    -- Don't want to begin showing audio samples 
    --  unti the switch for do_sample is high. 
    --  and also wait until the display fifo is empty
    --  to make sure that we aren't spitting out
    --  samples faster than it can handle
    --
    sample_done_sig <= (auto_done and disp_fifo_empty and sample_valid);

    --
    -- Put interesting things on the LEDs
    --
    led(7)          <= sample_valid;
    led(6)          <= '1' when std_match(sample, "11") else '0';
    led(5)          <= '1' when std_match(sample, "01") else '0';
    led(4)          <= '1' when std_match(sample, "00") else '0';
    led(3)          <= run_motors;
    led(2)          <= step;
    led(1)          <= dir;
    led(0)          <= tuned;

    --
    -- Need to synchronize the reset button
    --
    doReset : process(clk)
    begin
        if (rising_edge(clk)) then
            reset_sync  <= reset_unsync;
            n_reset     <= reset_sync;
        end if;
    end process;


end structural;
