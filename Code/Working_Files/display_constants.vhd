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

    -- A line for the 20-character display
    type    disp_line is array(0 to 19) of std_logic_vector(7 downto 0);

    constant auto_tune_line : disp_line :=
        -- A     u     t     o    ' '     T     u     n     e    ' '    X     X    ' '    S     t     r     i     n     g    ' '
        (X"41",X"75",X"74",X"6F",X"20",X"54",X"75",X"6E",X"65",X"20",X"58",X"58",X"20",X"53",X"74",X"72",X"69",X"6E",X"67",X"20");
    constant reg_tune_line  : disp_line := 
        --' '   ' '   ' '   ' '   ' '    T     u     n     e    ' '    X     X    ' '    S     t     r     i     n     g    ' '
        (X"20",X"20",X"20",X"20",X"20",X"54",X"75",X"6E",X"65",X"20",X"58",X"58",X"20",X"53",X"74",X"72",X"69",X"6E",X"67",X"20");
    constant free_tune_line : disp_line := 
        --' '   ' '   ' '   ' '   ' '    F     r     e     e    ' '    T     u     n     e    ' '   ' '   ' '   ' '   ' '   ' '
        (X"20",X"20",X"20",X"20",X"20",X"54",X"75",X"6E",X"65",X"20",X"58",X"58",X"20",X"53",X"20",X"20",X"20",X"20",X"20",X"20");
    constant target_freq_line : disp_line :=
        -- T    a     r     g     e     t    ' '    F     r     e     q    ' '    X     X     X     X     .     X     X     X
        (X"54",X"61",X"72",X"67",X"65",X"74",X"20",X"46",X"72",X"65",X"71",X"20",X"58",X"58",X"58",X"58",X"2E",X"58",X"58",X"58");
    constant input_freq_line : disp_line :=
        --I     n     p     u     t    ' '   ' '    F     r     e     q    ' '    X     X     X     X     .     X     X     X
        (X"49",X"6E",X"70",X"75",X"74",X"20",X"20",X"46",X"72",X"65",X"71",X"20",X"58",X"58",X"58",X"58",X"2E",X"58",X"58",X"58");
    constant note_line       : disp_line := 
        --  =     =     =    =     =     =     =     T     u     n    e     d     !      =     =     =     =     =     =     =  
        (X"49",X"6E",X"70",X"75",X"74",X"20",X"20",X"46",X"72",X"65",X"71",X"20",X"58",X"58",X"58",X"58",X"2E",X"58",X"58",X"58");
    constant auto_tune_running       : disp_line := 
        -- ' '   A     u     t     o    ' '     T     u     n     e    ' '    R    u     n     n     i     n     g    ' '   ' '
        (X"41",X"75",X"74",X"6F",X"20",X"54",X"75",X"6E",X"65",X"20",X"58",X"58",X"20",X"53",X"74",X"72",X"69",X"6E",X"67",X"20");
    constant auto_tune_stopped       : disp_line := 
        -- ' '   A     u     t     o    ' '     T     u     n     e    ' '   S     t     o     p     p     e     d    ' '   ' '
        (X"41",X"75",X"74",X"6F",X"20",X"54",X"75",X"6E",X"65",X"20",X"58",X"58",X"20",X"53",X"74",X"72",X"69",X"6E",X"67",X"20");

    type string_name is array(0 to 1) of std_logic_vector(7 downto 0);
    constant e2_string : string_name := (X"45", X"32");
    constant a2_string : string_name := (X"41", X"32");
    constant d3_string : string_name := (X"44", X"33");
    constant g3_string : string_name := (X"47", X"33");
    constant b3_string : string_name := (X"42", X"33");
    constant e4_string : string_name := (X"45", X"34");

    type string_names is array(0 to 5) of string_name;
    constant strings : string_names := (e2_string, a2_string, d3_string, g3_string, b3_string, e4_string);

    type string_freq is array(0 to 7) of std_logic_vector(7 downto 0);
    constant e2_freq : string_freq := (X"30", X"30", X"38", X"32", X"2E", X"34", X"30", X"37"); -- 82.407
    constant a2_freq : string_freq := (X"30", X"31", X"31", X"30", X"2E", X"30", X"30", X"30"); -- 110.000
    constant d3_freq : string_freq := (X"30", X"31", X"34", X"36", X"2E", X"38", X"33", X"32"); -- 146.832
    constant g3_freq : string_freq := (X"30", X"31", X"39", X"35", X"2E", X"39", X"39", X"38"); -- 195.998
    constant b3_freq : string_freq := (X"30", X"32", X"34", X"36", X"2E", X"39", X"34", X"32"); -- 246.942
    constant e4_freq : string_freq := (X"30", X"33", X"32", X"39", X"2E", X"36", X"32", X"38"); -- 329.628

    type string_freqs is array(0 to 5) of (string_freq);
    constant freqs : string_freqs := (e2_freq, a2_freq, d3_freq, g3_freq, b3_freq, e4_freq);

end package;