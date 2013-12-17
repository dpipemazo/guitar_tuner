----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:33:10 02/10/2010 
-- Design Name: 
-- Module Name:    DVI_Decoder_Data_Ch - Behavioral 
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

entity DVI_Decoder_Data_Ch is
    Port ( 
			Pixel_Clk 			: in  STD_LOGIC;
         Pixel_Clk_2x 		: in  STD_LOGIC;
         Pixel_Clk_10x 		: in  STD_LOGIC;
         Reset 				: in  STD_LOGIC;
         Clocks_Locked 		: in  STD_LOGIC;
         TMDS_Data_p 		: in  STD_LOGIC;
         TMDS_Data_n 		: in  STD_LOGIC;
         Rx_Serdes_Strobe 	: in  STD_LOGIC;
         Data 					: out  STD_LOGIC_VECTOR (7 downto 0);
         DE 					: out  STD_LOGIC;
         CH1 					: out  STD_LOGIC;
         CH0 					: out  STD_LOGIC;
         Ready 				: out  STD_LOGIC
			);
end DVI_Decoder_Data_Ch;

architecture Behavioral of DVI_Decoder_Data_Ch is

	COMPONENT serdes_1_to_n_data_s16_diff
	generic (
		S				: integer := 10 ;				-- Parameter to set the serdes factor 1..8
		D 				: integer := 1 ;				-- Set the number of inputs and outputs
		DIFF_TERM	: boolean := FALSE) ;		-- Enable or disable internal differential termination
	PORT(
		use_phase_detector 	: IN std_logic;
		datain_p 				: IN std_logic_vector(0 to 0);
		datain_n 				: IN std_logic_vector(0 to 0);
		rxioclk 					: IN std_logic;
		rx_serdesstrobe 		: IN std_logic;
		reset 					: IN std_logic;
		rx_toggle 				: IN std_logic;
		rx_bufg_pll_x2 		: IN std_logic;
		init_cal_done			: out std_logic;				
		bitslip 					: IN std_logic;          
		data_out 				: OUT std_logic_vector(9 downto 0)
		);
	END COMPONENT;

signal Clkx10 				: std_logic := '0';
signal Clkx1 				: std_logic := '0';
signal Clkx2 				: std_logic := '0';
signal rx_toggle 			: std_logic := '0';
signal pipe1 				: std_logic_vector(9 downto 0) := (others => '0');
signal pipe2 				: std_logic_vector(9 downto 0) := (others => '0');
signal Raw_Data_out_int	: std_logic_vector(9 downto 0) := (others => '0');
signal Raw_Data_out_Sync1x	: std_logic_vector(9 downto 0) := (others => '0');

constant pattern1 : std_logic_vector(9 downto 0) := "1101010100"; -- C[1:0] = 00;
constant pattern2 : std_logic_vector(9 downto 0) := "0010101011"; -- C[1:0] = 01;
constant pattern3 : std_logic_vector(9 downto 0) := "0101010100"; -- C[1:0] = 10;
constant pattern4 : std_logic_vector(9 downto 0) := "1010101011"; -- C[1:0] = 11;

signal bitslip 	: std_logic := '0';
signal state 		: integer range 0 to 9 := 0;
signal cal_clk 	: std_logic := '0';
signal enable 		: std_logic := '0';
signal rst_clk 	: std_logic := '0';
signal busyd 		: std_logic := '0';
signal count  		: std_logic_vector(3 downto 0) ;

signal Ready_pre		: std_logic := '0';
signal Ready_int		: std_logic := '0';
signal Channel_Ready	: std_logic := '0';
signal DE_pre 			: std_logic := '0';
signal DE_int 			: std_logic := '0';
signal Data_pre 		: std_logic_vector(7 downto 0) := (others => '0');
signal Data_int  		: std_logic_vector(7 downto 0) := (others => '0');
signal Data_Decode	: std_logic_vector(1 downto 0) := (others => '0');
signal CH1_pre			: std_logic := '0';
signal CH0_pre 		: std_logic := '0';
signal CH1_int			: std_logic := '0';
signal CH0_int 		: std_logic := '0';
signal Match_count	: std_logic_vector(4 downto 0) := (others => '0');

signal TMDS_Data_slv_p 		: STD_LOGIC_VECTOR(0 downto 0);
signal TMDS_Data_slv_n 		: STD_LOGIC_VECTOR(0 downto 0);

signal Attempt_cnt		: std_logic_vector(2 downto 0) := (others => '0');
signal Invert_Order		: std_logic	:= '0';
signal Hi_Lo_Write		: std_logic	:= '0';
signal init_cal_done		: std_logic	:= '0';
signal Match_Pattern1	: std_logic	:= '0';
signal Match_Pattern2	: std_logic	:= '0';
signal Match_Pattern3	: std_logic	:= '0';
signal Match_Pattern4	: std_logic	:= '0';
signal Data_Type			: STD_LOGIC_VECTOR(3 downto 0)	:= (others => '0');
signal Pixel_Clk_1x_CE	: std_logic	:= '0';


begin

-------------------------------------------------------
-- need to embelish on this to garuntee half word org.
process (Pixel_Clk_2x) 
begin
	if rising_edge(Pixel_Clk_2x) then
		if Clocks_Locked = '0' then
			rx_toggle <= '1' ;
		else
			rx_toggle <= not rx_toggle;
			Pixel_Clk_1x_CE <= not Pixel_Clk_1x_CE;
		end if;
	end if ;
end process ;
Hi_Lo_Write <= rx_toggle xor Invert_Order;
-------------------------------------------------------

TMDS_Data_slv_p(0) <= TMDS_Data_p;
TMDS_Data_slv_n(0) <= TMDS_Data_n;
                    
	Inst_serdes_1_to_n_data_s16_diff: serdes_1_to_n_data_s16_diff 
	generic map (
			S				=> 10 ,	-- Parameter to set the serdes factor 1..8
			D 				=> 1 ,	-- Set the number of inputs and outputs
			DIFF_TERM	=> FALSE)-- Enable or disable internal differential termination
	PORT MAP(
		use_phase_detector => Clocks_Locked,
		datain_p 			=> TMDS_Data_slv_p,
		datain_n 			=> TMDS_Data_slv_n,
		rxioclk 				=> Pixel_Clk_10x,
		rx_serdesstrobe 	=> Rx_Serdes_Strobe,
		reset 				=> Reset,
		rx_toggle 			=> Hi_Lo_Write,
		init_cal_done	 	=> init_cal_done,
		rx_bufg_pll_x2 	=> Pixel_Clk_2x,
		bitslip 				=> bitslip,
		data_out 			=> Raw_Data_out_int
	);


process (Pixel_Clk_2x)
begin
	if rising_edge(Pixel_Clk_2x) then 
	if Pixel_Clk_1x_CE = '1' then
		if Raw_Data_out_int = pattern1 then
			Match_Pattern1 <= '1';
		else
			Match_Pattern1 <= '0';
		end if;	
		if Raw_Data_out_int = pattern2 then
			Match_Pattern2 <= '1';
		else
			Match_Pattern2 <= '0';
		end if;	
		if Raw_Data_out_int = pattern3 then
			Match_Pattern3 <= '1';
		else
			Match_Pattern3 <= '0';
		end if;	
		if Raw_Data_out_int = pattern4 then
			Match_Pattern4 <= '1';
		else
			Match_Pattern4 <= '0';
		end if;	
	end if;
	end if;
end process;

---------------------------------------------
-- I started from a copy of the state machine
-- in the 1 to n vhdl. Will make more efficient
-- and pretty later.
process (Pixel_Clk_2x, Clocks_Locked)
begin
if Clocks_Locked = '0' then
	state 	<= 0 ;
	enable 	<= '0' ;
	bitslip 	<= '0' ;
	Attempt_cnt		<= (others => '0');
	Invert_Order 	<= '0';
	Match_count 	<= (others => '0');
	Channel_Ready 	<= '0';
elsif rising_edge(Pixel_Clk_2x) then 
 if Pixel_Clk_1x_CE = '1' then
	if init_cal_done = '1' then
		enable <= '1' ;
	end if ;
	if state = 0 and enable = '1' then
		state <= 1 ;
	elsif state = 1 then					-- 
		state <= 2 ;
		bitslip <= '1';
	elsif state = 2 then					-- 
		state <= 3 ;
		bitslip <= '0';
		count <= "0000" ;
	elsif state = 3 then					-- hang around
		count <= count + 1 ;
		if count = "1001" then
			state <= 4 ;
		end if ;
	elsif state = 4 then
		if Match_Pattern1 = '0' and Match_Pattern2 = '0' and Match_Pattern3 = '0' and Match_Pattern4 = '0' then
			state <= 1;
			if Attempt_cnt = 4 then
				Attempt_cnt <= (others => '0');
				Invert_Order <= not Invert_Order;
			else
				Attempt_cnt <= Attempt_cnt + 1;
			end if;
		else
			state <= 5 ;
		end if ;
	elsif state = 5 then					
		if Match_Pattern1 = '0' and Match_Pattern2 = '0' and Match_Pattern3 = '0' and Match_Pattern4 = '0' then
			state <=1;
			Match_count <= (others => '0');
		else
			if Match_count = 31 then
				Channel_Ready <= '1';
				state <= 6;
			else
				Match_count <= Match_count + 1;
				state <= 5 ;
			end if;
		end if ;
	elsif state = 6 then
		state <= 6;
	end if ;
 end if ;
end if ;
end process ;


-------------------------------------------
-- need to confirm crossing clock domain from 
-- PLL outputs!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
process(Pixel_Clk_2x)
begin
	if rising_edge(Pixel_Clk_2x) then 
	if Pixel_Clk_1x_CE = '1' then
		Raw_Data_out_Sync1x <= Raw_Data_out_int;
	end if;
	end if;
end process;

Data_Type <= Match_Pattern4 & Match_Pattern3 & Match_Pattern2 & Match_Pattern1;

process(Pixel_Clk_2x)
begin
	if rising_edge(Pixel_Clk_2x) then 
	if Pixel_Clk_1x_CE = '1' then
		Ready_pre <= Channel_Ready;
		case(Data_Type) is 
			when "0001" =>
				DE_pre 	<= '0';
				Data_pre 	<= "00000000";
				CH1_pre	<= '0';
				CH0_pre 	<= '0';
			when "0010" =>
				DE_pre 	<= '0';
				Data_pre 	<= "00000000";
				CH1_pre	<= '0';
				CH0_pre 	<= '1';
			when "0100" =>
				DE_pre 	<= '0';
				Data_pre 	<= "00000000";
				CH1_pre	<= '1';
				CH0_pre 	<= '0';
			when "1000" =>
				DE_pre 	<= '0';
				Data_pre 	<= "00000000";
				CH1_pre	<= '1';
				CH0_pre 	<= '1';
			when others =>
				DE_pre 	<= '1';
				CH1_pre	<= CH1_pre;
				CH0_pre 	<= CH0_pre;
				Data_pre <= Raw_Data_out_Sync1x(7 downto 0);
				Data_Decode <= Raw_Data_out_Sync1x(9 downto 8);
			end case;
	end if;
	end if;
end process;

process(Pixel_Clk_2x)
begin
	if rising_edge(Pixel_Clk_2x) then 
	if Pixel_Clk_1x_CE = '1' then
		Ready_int <= Ready_pre;
		DE_int	<= DE_pre;
		CH1_int	<= CH1_pre;
		CH0_int 	<= CH0_pre;
		case(Data_Decode) is 
			when "00" =>
				Data_int(0) 	<= Data_pre(0);
				Data_int(1) 	<= Data_pre(1) XNOR Data_pre(0);
				Data_int(2) 	<= Data_pre(2) XNOR Data_pre(1);
				Data_int(3) 	<= Data_pre(3) XNOR Data_pre(2);
				Data_int(4) 	<= Data_pre(4) XNOR Data_pre(3);
				Data_int(5) 	<= Data_pre(5) XNOR Data_pre(4);
				Data_int(6) 	<= Data_pre(6) XNOR Data_pre(5);
				Data_int(7) 	<= Data_pre(7) XNOR Data_pre(6);
			when "01" =>
				Data_int(0) 	<= Data_pre(0);
				Data_int(1) 	<= Data_pre(1) XOR Data_pre(0);
				Data_int(2) 	<= Data_pre(2) XOR Data_pre(1);
				Data_int(3) 	<= Data_pre(3) XOR Data_pre(2);
				Data_int(4) 	<= Data_pre(4) XOR Data_pre(3);
				Data_int(5) 	<= Data_pre(5) XOR Data_pre(4);
				Data_int(6) 	<= Data_pre(6) XOR Data_pre(5);
				Data_int(7) 	<= Data_pre(7) XOR Data_pre(6);
			when "10" =>
				Data_int(0) 	<= not Data_pre(0);
				Data_int(1) 	<= not Data_pre(1) XNOR not Data_pre(0);
				Data_int(2) 	<= not Data_pre(2) XNOR not Data_pre(1);
				Data_int(3) 	<= not Data_pre(3) XNOR not Data_pre(2);
				Data_int(4) 	<= not Data_pre(4) XNOR not Data_pre(3);
				Data_int(5) 	<= not Data_pre(5) XNOR not Data_pre(4);
				Data_int(6) 	<= not Data_pre(6) XNOR not Data_pre(5);
				Data_int(7) 	<= not Data_pre(7) XNOR not Data_pre(6);
			when "11" =>
				Data_int(0) 	<= not Data_pre(0);
				Data_int(1) 	<= not Data_pre(1) XOR not Data_pre(0);
				Data_int(2) 	<= not Data_pre(2) XOR not Data_pre(1);
				Data_int(3) 	<= not Data_pre(3) XOR not Data_pre(2);
				Data_int(4) 	<= not Data_pre(4) XOR not Data_pre(3);
				Data_int(5) 	<= not Data_pre(5) XOR not Data_pre(4);
				Data_int(6) 	<= not Data_pre(6) XOR not Data_pre(5);
				Data_int(7) 	<= not Data_pre(7) XOR not Data_pre(6);
			when others =>
				Data_int	 	<= Data_pre;
		end case;
	end if;
	end if;
end process;

process(Pixel_Clk)
begin
	if rising_edge(Pixel_Clk) then 
		Data 	<= Data_int;
		Ready <= Ready_int;
		CH1 	<= CH1_int;
		CH0 	<= CH0_int;
		DE		<= DE_int;
	end if;
end process;


end Behavioral;

