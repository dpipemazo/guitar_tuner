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

    -- Reset String
    type    reset_array is array(0 to 79) of std_logic_vector(7 downto 0);
    constant reset_string : reset_array :=
        -- Declare the reset string for now in constant form in four lines of 
        --  20 characters separated by underscores
        --
        --F     P     G     A    ' '    P     i     t     c     h    ' '   D      e     t     e     c     t     o     r    ' '
       (X"46",X"50",X"47",X"41",X"20",X"50",X"69",X"74",X"63",X"68",X"20",X"44",X"65",X"74",X"65",X"63",X"74",X"6F",X"72",X"20",
        --A     u     t     o    ' '    T     u     n     e    ' '    X    X     ' '    S     t     r     i     n     g    ' '
        X"41",X"75",X"74",X"6F",X"20",X"54",X"75",X"6E",X"65",X"20",X"58",X"58",X"20",X"53",X"74",X"72",X"69",X"6E",X"67",X"20",
        --T     a     r     g     e     t    ' '    F     r     e     q    ' '    X     X     X     X     .     X     X     X
        X"54",X"61",X"72",X"67",X"65",X"74",X"20",X"46",X"72",X"65",X"71",X"20",X"58",X"58",X"58",X"58",X"2E",X"58",X"58",X"58",
        --I     n     p     u     t    ' '   ' '    F     r     e     q    ' '    X     X     X     X     .     X     X     X
        X"49",X"6E",X"70",X"75",X"74",X"20",X"20",X"46",X"72",X"65",X"71",X"20",X"58",X"58",X"58",X"58",X"2E",X"58",X"58",X"58");

end package;