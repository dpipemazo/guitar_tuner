----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:48:39 02/12/2010 
-- Design Name: 
-- Module Name:    DVI_Decoder - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DVI_Decoder is
    Port ( TMDS_Clk_p 		: in  STD_LOGIC;
           TMDS_Clk_n 		: in  STD_LOGIC;
           TMDS_Data_Ch_p 	: in  STD_LOGIC_VECTOR (2 downto 0);
           TMDS_Data_Ch_n 	: in  STD_LOGIC_VECTOR (2 downto 0);
           Reset 				: in  STD_LOGIC;
			  Ready				: out  STD_LOGIC;
           Pixel_Clock 		: out  STD_LOGIC;
           RGB 				: out  std_logic_vector(23 downto 0);
           DE 					: out  STD_LOGIC;
           VSync 				: out  STD_LOGIC;
           HSync 				: out  STD_LOGIC);
end DVI_Decoder;

architecture Behavioral of DVI_Decoder is


	COMPONENT serdes_1_to_n_clk_pll_s16_diff
generic (
	PLLD 			: integer;   			-- Parameter to set division for PLL 
	PLLX 			: integer;   			-- Parameter to set multiplier for PLL
	CLKIN_PERIOD 		: real ;			-- clock period (ns) of input clock on clkin_p
	S			: integer;			-- Parameter to set the serdes factor 1..8
	BS 			: boolean ;   			-- Parameter to enable bitslip TRUE or FALSE
	DIFF_TERM		: boolean) ;			-- Enable or disable internal differential termination
	PORT(
		clkin_p : IN std_logic;
		clkin_n : IN std_logic;
		reset : IN std_logic;
		pattern1 : IN std_logic_vector(9 downto 0);          
		rxioclk : OUT std_logic;
		rx_serdesstrobe : OUT std_logic;
		rx_bufg_pll_x1 : OUT std_logic;
		rx_bufg_pll_x2 : OUT std_logic;
		bitslip : OUT std_logic;
		rx_toggle : OUT std_logic;
		datain : OUT std_logic_vector(9 downto 0);
		rx_bufpll_lckd : OUT std_logic;
		Clock_Stable		: out std_logic
		);
	END COMPONENT;


	COMPONENT DVI_Decoder_Data_Ch
	PORT(
		Pixel_Clk 		: IN std_logic;
		Pixel_Clk_2x 	: IN std_logic;
		Pixel_Clk_10x 	: IN std_logic;
		Reset 			: IN std_logic;
		Clocks_Locked 	: IN std_logic;
		TMDS_Data_p		: IN std_logic;
		TMDS_Data_n 	: IN std_logic;
		Rx_Serdes_Strobe : IN std_logic;          
		Data 				: OUT std_logic_vector(7 downto 0);
		DE 				: OUT std_logic;
		CH1 				: OUT std_logic;
		CH0 				: OUT std_logic;
		Ready 			: OUT std_logic
		);
	END COMPONENT;

	COMPONENT DVI_Decoder_Assy
	PORT(
		Pixel_Clk : IN std_logic;
		Ready_Red : IN std_logic;
		Ready_Grn : IN std_logic;
		Ready_Blu : IN std_logic;
		DE_Red : IN std_logic;
		DE_Grn : IN std_logic;
		DE_Blu : IN std_logic;
		Data_Red : IN std_logic_vector(7 downto 0);
		Data_Grn : IN std_logic_vector(7 downto 0);
		Data_Blu : IN std_logic_vector(7 downto 0);
		VSync_in : IN std_logic;
		HSync_in : IN std_logic;          
		DE : OUT std_logic;
		VSync : OUT std_logic;
		HSync : OUT std_logic;
		RGB : OUT std_logic_vector(23 downto 0)
		);
	END COMPONENT;

signal Pixel_Clk 			: std_logic := '0';
signal Pixel_Clk_2x 		: std_logic := '0';
signal Pixel_Clk_10x 	: std_logic := '0';
signal All_Locked 		: std_logic := '0';
signal Rx_Serdes_Strobe	: std_logic := '0';

signal RGB_int		: std_logic_vector(23 downto 0) := (others => '0');
signal Raw_Data_Red	: std_logic_vector(7 downto 0) := (others => '0');
signal Raw_Data_Grn	: std_logic_vector(7 downto 0) := (others => '0');
signal Raw_Data_Blu	: std_logic_vector(7 downto 0) := (others => '0');
signal Raw_DE_Red		: std_logic := '0';
signal Raw_DE_Grn		: std_logic := '0';
signal Raw_DE_Blu		: std_logic := '0';
signal Raw_HSync		: std_logic := '0';
signal Raw_VSync		: std_logic := '0';
signal Ready_Red	: std_logic := '0';
signal Ready_Grn	: std_logic := '0';
signal Ready_Blu	: std_logic := '0';
signal DE_int	: std_logic := '0';
signal HSync_int	: std_logic := '0';
signal VSync_int	: std_logic := '0';
signal Clock_Stable	: std_logic := '0';
signal data_chan_reset	: std_logic := '0';
signal Ready_chans	: std_logic := '0';


signal   CONTROL : STD_LOGIC_VECTOR(35 DOWNTO 0);

signal 	clk_tap_count		 	: std_logic_vector(8 downto 0) := (others => '0');
signal 	Clk_Manual_Ctrl		 	: std_logic_vector(1 downto 0) := (others => '0');
signal 	Red_tap_count		 	: std_logic_vector(8 downto 0) := (others => '0');
signal 	Red_Manual_Ctrl		 	: std_logic_vector(1 downto 0) := (others => '0');
signal 	Green_tap_count		 	: std_logic_vector(8 downto 0) := (others => '0');
signal 	Green_Manual_Ctrl		 	: std_logic_vector(1 downto 0) := (others => '0');
signal 	Blue_tap_count		 	: std_logic_vector(8 downto 0) := (others => '0');
signal 	Blue_Manual_Ctrl		 	: std_logic_vector(1 downto 0) := (others => '0');

begin

                         
Data_Chan_Reset <= reset or (not All_Locked) or (not Clock_Stable);

	Inst_clockin: serdes_1_to_n_clk_pll_s16_diff 
		generic map (
	PLLD 			=> 1,   			-- Parameter to set division for PLL 
	PLLX 			=> 10 ,   			-- Parameter to set multiplier for PLL
	CLKIN_PERIOD 	=>	10.000 ,			-- clock period (ns) of input clock on clkin_p
	S			=> 10 ,			-- Parameter to set the serdes factor 1..8
	BS 			=>TRUE    ,			-- Parameter to enable bitslip TRUE or FALSE
	DIFF_TERM	=>	TRUE) 			-- Enable or disable internal differential termination
	PORT MAP(
		clkin_p => TMDS_Clk_p,
		clkin_n => TMDS_Clk_n,
		rxioclk => Pixel_Clk_10x,
		rx_serdesstrobe => Rx_Serdes_Strobe,
		reset => Reset,
		pattern1 => "0011111000",
		rx_bufg_pll_x1 => Pixel_Clk,
		rx_bufg_pll_x2 => Pixel_Clk_2x,
		bitslip => open,
		rx_toggle => open,
		datain => open,
		rx_bufpll_lckd => All_Locked,
		Clock_Stable	=> Clock_Stable
	);


	Inst_DVI_Decoder_Data_Ch_Blue: DVI_Decoder_Data_Ch PORT MAP(
		Pixel_Clk => Pixel_Clk,
		Pixel_Clk_2x => Pixel_Clk_2x,
		Pixel_Clk_10x => Pixel_Clk_10x,
		Reset => Data_Chan_Reset,
		Clocks_Locked => Clock_Stable,
		TMDS_Data_p => TMDS_Data_Ch_p(0),
		TMDS_Data_n => TMDS_Data_Ch_n(0),
		Rx_Serdes_Strobe => Rx_Serdes_Strobe,
		Data => Raw_Data_Blu,
		DE => Raw_DE_Blu,
		CH1 => Raw_VSync,
		CH0 => Raw_HSync,
		Ready => Ready_Blu
	);

	Inst_DVI_Decoder_Data_Ch_Grn: DVI_Decoder_Data_Ch PORT MAP(
		Pixel_Clk => Pixel_Clk,
		Pixel_Clk_2x => Pixel_Clk_2x,
		Pixel_Clk_10x => Pixel_Clk_10x,
		Reset => Data_Chan_Reset,
		Clocks_Locked => Clock_Stable,
		TMDS_Data_p => TMDS_Data_Ch_p(1),
		TMDS_Data_n => TMDS_Data_Ch_n(1),
		Rx_Serdes_Strobe => Rx_Serdes_Strobe,
		Data => Raw_Data_Grn,
		DE => Raw_DE_Grn,
		CH1 => open,
		CH0 => open,
		Ready => Ready_Grn
	);

	Inst_DVI_Decoder_Data_Ch_Red: DVI_Decoder_Data_Ch PORT MAP(
		Pixel_Clk => Pixel_Clk,
		Pixel_Clk_2x => Pixel_Clk_2x,
		Pixel_Clk_10x => Pixel_Clk_10x,
		Reset => Data_Chan_Reset,
		Clocks_Locked => Clock_Stable,
		TMDS_Data_p => TMDS_Data_Ch_p(2),
		TMDS_Data_n => TMDS_Data_Ch_n(2),
		Rx_Serdes_Strobe => Rx_Serdes_Strobe,
		Data => Raw_Data_Red,
		DE => Raw_DE_Red,
		CH1 => open,
		CH0 => open,
		Ready => Ready_Red
	);


	Inst_DVI_Decoder_Assy: DVI_Decoder_Assy PORT MAP(
		Pixel_Clk => Pixel_Clk,
		Ready_Red => Ready_Red,
		Ready_Grn => Ready_Grn,
		Ready_Blu => Ready_Blu,
		DE_Red => Raw_DE_Red,
		DE_Grn => Raw_DE_Grn,
		DE_Blu => Raw_DE_Blu,
		Data_Red => Raw_Data_Red,
		Data_Grn => Raw_Data_Grn,
		Data_Blu => Raw_Data_Blu,
		VSync_in => Raw_VSync,
		HSync_in => Raw_HSync,
		DE => DE_int,
		VSync => VSync_int,
		HSync => HSync_int,
		RGB => RGB_int
	);

process(Pixel_Clk)
begin
	if rising_edge(Pixel_Clk) then
		if Ready_Red = '1' and Ready_Grn = '1' and Ready_Blu = '1' then
			Ready_chans <= '1';
		else
			Ready_chans <= '0';
		end if;		
	end if;
end process;

ready <= All_Locked and Ready_chans;
RGB 	<= RGB_int;
VSync <= VSync_int;
HSync <= HSync_int;
DE 	<= DE_int;
Pixel_Clock <= Pixel_Clk;

end Behavioral;

