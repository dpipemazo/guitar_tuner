-----------------------------------------------------------------------------
--
--  DISPLAY CONSTANTS
--      This file is to be used in conjuction with the DISPLAY module
--
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;


package display_constants is

    -- Display States
    type display_states is(
        -- General states
        IDLE, 
        RESET,
        STATE_DONE,
        -- States for updating a character
        UPDATE_CHAR,
        UPDATE_CHAR_DATA,
        -- States for updating a line
        UPDATE_LINE, 
        SERIAL_GET_CHAR,
        -- "Function Calls" for both to use
        LCD_SET_ADDRESS, 
        LCD_SEND_CHAR, 
        LCD_WAIT
    );

    -- States for the state counter
    type state_count_states is(
        INC, 
        DEC,
        KEEP,
        RESET
    );

    -- Standard wait values (assuming 200KHz clock)
    constant wait_4_ms : std_logic_vector(9 downto 0)   := "1100100001";
    constant wait_100_us : std_logic_vector(9 downto 0) := "0000010100";
    constant wait_37_us : std_logic_vector(9 downto 0)  := "0000001000";

    -- LCD address mappings
    constant line_0_start : std_logic_vector(6 downto 0) := "0000000";
    constant line_1_start : std_logic_vector(6 downto 0) := "1000000";
    constant line_2_start : std_logic_vector(6 downto 0) := "0010100";
    constant line_3_start : std_logic_vector(6 downto 0) := "1010100";

    -- Serial Constants
    constant serial_read_instr  : std_logic_vector(7 downto 0) := "00000011";
    constant serial_instr_bits  : std_logic_vector(4 downto 0) := "00111";
    constant serial_char_num    : integer := 20;
    constant serial_addr_bits   : std_logic_vector(4 downto 0) := "10111";
    constant serial_char_bits   : std_logic_vector(4 downto 0) := "00111";

    -- Reset Constants
    constant reset_special_function_set : std_logic_vector(7 downto 0) := "00110000";
    constant reset_reg_function_set     : std_logic_vector(7 downto 0) := "00111000";
    constant reset_display_set          : std_logic_vector(7 downto 0) := "00001100";
    constant reset_display_clear        : std_logic_vector(7 downto 0) := "00000001";
    constant reset_entry_mode_set       : std_logic_vector(7 downto 0) := "00000110";

end package;