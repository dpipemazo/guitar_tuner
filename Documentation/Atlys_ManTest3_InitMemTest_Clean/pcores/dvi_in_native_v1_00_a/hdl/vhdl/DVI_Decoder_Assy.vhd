----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:29:28 02/13/2010 
-- Design Name: 
-- Module Name:    DVI_Decoder_Assy - Behavioral 
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

entity DVI_Decoder_Assy is
    Port ( Pixel_Clk : in  STD_LOGIC;
           Ready_Red : in  STD_LOGIC;
           Ready_Grn : in  STD_LOGIC;
           Ready_Blu : in  STD_LOGIC;
           DE_Red 	: in  STD_LOGIC;
           DE_Grn 	: in  STD_LOGIC;
           DE_Blu 	: in  STD_LOGIC;
           Data_Red 	: in  STD_LOGIC_VECTOR (7 downto 0);
           Data_Grn 	: in  STD_LOGIC_VECTOR (7 downto 0);
           Data_Blu 	: in  STD_LOGIC_VECTOR (7 downto 0);
           VSync_in 	: in  STD_LOGIC;
           HSync_in 	: in  STD_LOGIC;
           DE 			: out  STD_LOGIC;
           VSync 		: out  STD_LOGIC;
           HSync 		: out  STD_LOGIC;
           RGB 		: out  STD_LOGIC_VECTOR (23 downto 0));
end DVI_Decoder_Assy;

architecture Behavioral of DVI_Decoder_Assy is

signal DE_All				: STD_LOGIC := '0';
signal DE_All_pre			: STD_LOGIC := '0';
signal Enable_Outputs	: STD_LOGIC := '0';
signal Matched_DE			: STD_LOGIC := '0';
signal Matched_VSync		: STD_LOGIC := '0';
signal Matched_HSync		: STD_LOGIC := '0';
signal Matched_RGB		: STD_LOGIC_VECTOR(23 downto 0) :=(others => '0');

type Data_SRL_pipe is array (0 to 7) of STD_LOGIC_VECTOR(7 downto 0);
signal Data_Red_SRL : Data_SRL_pipe;
signal Data_Grn_SRL : Data_SRL_pipe;
signal Data_Blu_SRL : Data_SRL_pipe;

signal Data_VSync_SRL	: STD_LOGIC_VECTOR(7 downto 0) :=(others => '0');
signal Data_HSync_SRL	: STD_LOGIC_VECTOR(7 downto 0) :=(others => '0');
signal Sync_Index_Red	: integer range 0 to 7 := 0; 
signal Sync_Index_Grn	: integer range 0 to 7 := 0;
signal Sync_Index_Blu	: integer range 0 to 7 := 0;
signal Pipe_Cnt_Red		: integer range 0 to 7 := 0; 
signal Pipe_Cnt_Grn		: integer range 0 to 7 := 0;
signal Pipe_Cnt_Blu		: integer range 0 to 7 := 0;

begin

DE_All <= DE_Red and DE_Grn and DE_Blu;

process(Pixel_Clk)
begin
	if rising_edge(Pixel_Clk) then
		if Ready_Red = '1' and Ready_Grn = '1' and Ready_Blu = '1' then
			Enable_Outputs <= '1';
		else
			Enable_Outputs <= '0';
		end if;		
	end if;
end process;

process(Pixel_Clk)
begin
	if rising_edge(Pixel_Clk) then
		if DE_Red ='0' and DE_Grn = '0' and DE_Blu = '0' then
			Pipe_Cnt_Red <= 0;
			Pipe_Cnt_Grn <= 0;
			Pipe_Cnt_Blu <= 0;
		else
			if DE_Red = '1' and DE_All = '0' then 
				if Pipe_Cnt_Red < 6 then
					Pipe_Cnt_Red <= Pipe_Cnt_Red + 1;
				end if;		
			end if;		
			if DE_Grn = '1' and DE_All = '0' then 
				if Pipe_Cnt_Grn < 6 then
					Pipe_Cnt_Grn <= Pipe_Cnt_Grn + 1;
				end if;		
			end if;		
			if DE_Blu = '1' and DE_All = '0' then 
				if Pipe_Cnt_Blu < 6 then
					Pipe_Cnt_Blu <= Pipe_Cnt_Blu + 1;
				end if;		
			end if;		
		end if;
	end if;
end process;

process(Pixel_Clk)
begin
	if rising_edge(Pixel_Clk) then
		DE_All_pre <= DE_all;
		if DE_All_pre ='0' and DE_All = '1' then
			Sync_Index_Red <= Pipe_Cnt_Red;
			Sync_Index_Grn <= Pipe_Cnt_Grn;
			Sync_Index_Blu <= Pipe_Cnt_Blu;
		end if;		
	end if;
end process;

process(Pixel_Clk)
begin
	if rising_edge(Pixel_Clk) then
		if DE_Red = '1' then 
			for i in 0 to 6 loop
				Data_Red_SRL(i+1) <= Data_Red_SRL(i);
			end loop;
			Data_Red_SRL(0) <= Data_Red;
		end if;		
		if DE_Grn = '1' then 
			for i in 0 to 6 loop
				Data_Grn_SRL(i+1) <= Data_Grn_SRL(i);
			end loop;
			Data_Grn_SRL(0) <= Data_Grn;
		end if;		
		if DE_Blu = '1' then 
			for i in 0 to 6 loop
				Data_Blu_SRL(i+1) <= Data_Blu_SRL(i);
			end loop;
			Data_Blu_SRL(0) <= Data_Blu;
		end if;		
			Data_VSync_SRL <= Data_VSync_SRL(6 downto 0) & VSync_in;
			Data_HSync_SRL <= Data_HSync_SRL(6 downto 0) & HSync_in;
	end if;
end process;

Matched_DE 						<= DE_All_pre;
Matched_RGB(23 downto 16) 	<= Data_Red_SRL(Sync_Index_Red);
Matched_RGB(15 downto 8) 	<= Data_Grn_SRL(Sync_Index_Grn);
Matched_RGB(7 downto 0)	 	<= Data_Blu_SRL(Sync_Index_Blu);
Matched_VSync				 	<= Data_VSync_SRL(Sync_Index_Blu);
Matched_HSync				 	<= Data_HSync_SRL(Sync_Index_Blu);

process(Pixel_Clk)
begin
	if rising_edge(Pixel_Clk) then
		if Enable_Outputs = '1' then
			DE 		<= Matched_DE;
         VSync 	<= Matched_VSync;
         HSync 	<= Matched_HSync;
			if DE_All_pre = '1' then
				RGB 	<= Matched_RGB;
			else
				RGB 	<= (others => '0');
			end if;
		else
           DE 		<= '0';
           VSync 	<= '0';
           HSync 	<= '0';
           RGB 	<= (others => '0');
		end if;		
	end if;
end process;

end Behavioral;

