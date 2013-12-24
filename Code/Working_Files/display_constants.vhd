-----------------------------------------------------------------------------
--
--  DISPLAY CONSTANTS
--      This file is to be used in conjuction with the DISPLAY module
--
-----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;


package display_constants is

    -- LCD address mappings
    constant line_0_start : std_logic_vector(6 downto 0) := "0000000";
    constant line_1_start : std_logic_vector(6 downto 0) := "1000000";
    constant line_2_start : std_logic_vector(6 downto 0) := "0010100";
    constant line_3_start : std_logic_vector(6 downto 0) := "1010100";

    -- Reset Constants
    constant reset_special_function_set : std_logic_vector(7 downto 0) := "00110000";
    constant reset_reg_function_set     : std_logic_vector(7 downto 0) := "00111000";
    constant reset_display_set          : std_logic_vector(7 downto 0) := "00001100";
    constant reset_display_clear        : std_logic_vector(7 downto 0) := "00000001";
    constant reset_entry_mode_set       : std_logic_vector(7 downto 0) := "00000110";

end package;