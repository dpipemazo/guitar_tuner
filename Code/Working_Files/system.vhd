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
        do_sample   : in  std_logic;
        volume      : in  std_logic_vector(4 downto 0);

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
        lcd_data    : out std_logic_vector(7 downto 0)

    );
end system;

architecture structural of system is 

    -- Debounced buttons
    signal db_buttons   : std_logic_vector(4 downto 0);

    -- Signals for the display
    signal disp_wr_en        : std_logic;
    signal disp_data         : std_logic_vector(15 downto 0);
    signal disp_fifo_full    : std_logic;

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

    -- Signals for the user interface unit to talk to the display
    signal ui_wr_en         : std_logic;
    signal ui_data          : std_logic_vector(15 downto 0);

    -- Need to syhcnronize the reset button into our circuit
    signal reset_sync       : std_logic;
    signal n_reset          : std_logic;

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
            n_reset     => n_reset,
            result_div  => auto_result_div,
            result_idx  => auto_result_idx,
            done        => auto_done                                               
        );

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
            disp_fifo_full  => disp_fifo_full
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
            disp_fifo_full      => disp_fifo_full
        );

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
    --
    sample_done_sig <= (auto_done and do_sample);

    --
    -- Put interesting things on the LEDs
    --
    led(7) <= sample_valid;
    led(6 downto 5) <= sample;
    led(4) <= disp_fifo_full;
    led(3 downto 0) <= (others => '0'); -- nothing else for now.

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
