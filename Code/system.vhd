--
-- System-level VHDL setup
--

library work;
use work.control;
use work.sampling;
use work.display_constants.all;
use work.display;
use work.bin2bcd;
use work.gaincontrol;
use work.steppercontrol;
use work.clockdiv;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_arith.all;

-- Entity declaration
entity system is 
    
    port(

        -- system clock
        clk         : in std_logic;

        -- pushbuttons
        btn         : in std_logic_vector(5 downto 0);

        -- display I/O
        lcd_rs      : out std_logic;
        lcd_rw      : out std_logic;
        lcd_e       : out std_logic;
        lcd_data    : out std_logic_vector(7 downto 0);

        -- Serial I/O
        FlashCLK        : out std_logic; 
        FlashCS         : out std_logic;   
        FlashDQ0        : out std_logic;
        FlashDQ1        : in std_logic;

        -- Stepper Motor I/0
        step            : out std_logic;
        dir             : out std_logic;
        enable          : out std_logic;
        sw0             : in std_logic;

        -- Adjustable potentiometer I/O
        gain_pot_cs     : out std_logic;
        gain_pot_data   : out std_logic;
        gain_pot_clk    : out std_logic;

        -- LEDs (uncomment to eventually use them or 
        --  use them for debugging)
        -- Led             : out std_logic_vector(7 downto 0);

        -- Comparator results
        sig_above_pos : in std_logic;
        sig_below_neg : in std_logic

    );
end system;

architecture structural of system is 

    -- Sampling signals
    signal sample_start : std_logic;
    signal sample_done : std_logic;
    signal detected_freq : std_logic_vector(31 downto 0);

    -- BCD conversion signals
    signal bcd_conv_start : std_logic;
    signal bcd_conv_done : std_logic;
    signal bcd_freq : std_logic_vector(51 downto 0);

    -- Display signals
    signal display_line_start  : std_logic;
    signal display_char_start  : std_logic;
    signal display_reset_start : std_logic;
    signal display_done        : std_logic;
    signal display_ack         : std_logic;
    signal display_data        : std_logic_vector(7 downto 0);
    signal line_to_update      : std_logic_vector(1 downto 0);
    signal char_to_update      : std_logic_vector(4 downto 0);
    signal display_clk         : std_logic;

    -- Gain control signals
    signal gain_start          : std_logic;
    signal gain_inc_dec        : std_logic;
    signal gain_reset          : std_logic;
    signal gain_done           : std_logic;
    signal gain_diff           : std_logic_vector(12 downto 0);

    -- constants and force an update
    constant num_samples : integer := 5120;

    -- stepper signals
    signal string_num           : std_logic_vector(2 downto 0);
    signal auto_start           : std_logic;
    signal auto_done            : std_logic;
    signal auto_first           : std_logic;
    signal auto_ack             : std_logic;
    signal tuned                : std_logic;

    -- Diluted clocks
    signal clk_400khz   : std_logic;
    signal clk_200khz   : std_logic;
    signal clk_100khz   : std_logic;

begin

    --
    -- TODO: SYNC CLOCK SIGNALS WITH DFFS
    --

    --
    -- Divider for creating clocks which we need.
    --
    -- We need:
    --
    --  A 400 KHz clock for the stepper motor unit
    --  A 200 KHz clock for debouncing buttons and for
    --      the display unit
    --  A 100 KHz clock for sampling
    --  
    clkdiv: entity CLOCKDIV
        port map(
            clk_100mhz => clk,
            clk_400khz => clk_400khz, 
            clk_200khz => clk_200khz, 
            clk_100khz => clk_100khz
        );

    --
    -- Wire up all of our individual units
    -- 
    crtl: entity CONTROL 
        port map(
            clk                 => clk,
            debounce_clk        => clk_200khz, 
            btn                 => btn,   
            sample_start        => sample_start,
            sample_done         => sample_done, 
            bcd_conv_start      => bcd_conv_start, 
            bcd_conv_done       => bcd_conv_done, 
            display_line_start  => display_line_start ,
            display_char_start  => display_char_start ,
            display_reset_start => display_reset_start,
            display_done        => display_done,
            display_ack         => display_ack,
            display_data        => display_data,
            line_to_update      => line_to_update,
            char_to_update      => char_to_update,            
            bcd_freq            => bcd_freq, 
            string_num          => string_num, 
            auto_start          => auto_start, 
            auto_done           => auto_done,
            tuned               => tuned
        );

    smpl: entity SAMPLING 
        generic map(
            -- Take 5120 sampples
            num_samples => num_samples,
            -- Do the autocorrelation in blocks of 128
            auto_block_size => 128
        )
        
        port map(
            clk                 => clk, 
            sample_clock        => clk_100khz,
            start               => sample_start,
            done                => sample_done,
            sig_pos             => sig_above_pos,
            sig_neg             => sig_below_neg,
            detected_freq       => detected_freq,
            gain_start          => gain_start,
            gain_inc_dec        => gain_inc_dec,
            gain_reset          => gain_reset,
            gain_done           => gain_done,
            gain_diff           => gain_diff
        );

    bcd: entity BIN2BCD 
        port map(
            clk                 => clk, 
            start               => bcd_conv_start, 
            done                => bcd_conv_done, 
            binary_in           => detected_freq, 
            bcd_out             => bcd_freq
        );

    dsply: entity DISPLAY
        port map(
            clk                 => clk_200khz, 
            lcd_rs              => lcd_rs, 
            lcd_rw              => lcd_rw, 
            lcd_e               => lcd_e, 
            lcd_data            => lcd_data,
            FlashCLK            => FlashCLK,
            FlashCS             => FlashCS,
            FlashDQ0            => FlashDQ0,
            FlashDQ1            => FlashDQ1,
            start_line_update   => display_line_start,
            start_char_update   => display_char_start,
            do_reset            => display_reset_start,
            done                => display_done,
            command_ack         => display_ack,
            display_data        => display_data,
            line_to_update      => line_to_update,
            char_to_update      => char_to_update
        );

    gainctrl : entity GAINCONTROL
        generic map(
            num_samples => conv_std_logic_vector(num_samples, 13)
        )

        port map(
            clk                 => clk, 
            pot_cs              => gain_pot_cs,
            pot_data            => gain_pot_data,
            pot_clk             => gain_pot_clk,
            start               => gain_start,
            done                => gain_done,
            reset               => gain_reset,
            inc_dec             => gain_inc_dec,
            gain_diff           => gain_diff
        );

    sptctrl : entity STEPPERCONTROL
        port map(
            clk                 => clk, 
            step_clk            => clk_400khz,
            step                => step, 
            dir                 => dir, 
            enable              => enable, 
            dir_switch          => sw0, 
            freq_detected       => detected_freq(12 downto 0),
            string_num          => string_num,
            run_motor           => auto_start, 
            motor_done          => auto_done, 
            tuned               => tuned
        );

end structural;
