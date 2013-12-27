-- Hi Emacs, this is -*- mode: vhdl; -*-
----------------------------------------------------------------------------------------------------
-- dc97.vhd - AC97 controller, AC97 setup FSM and package with components declaration
-- Based on verilog code found at http://web.mit.edu/6.111/www/f2008/handouts/labs/lab4.html
--
-- 2009 Javier Valcarce, <javier.valcarce@gmail.com>
-- Universidad Rey Juan Carlos
----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package pkg_dc97 is

  component dc97 
    port (
      n_reset      : in  std_logic; --active-low
      clk          : in  std_logic;
      -- ac97 interface signals
      ac97_sdata_o : out std_logic;
      ac97_sdata_i : in  std_logic;
      ac97_sync    : out std_logic;
      ac97_bitclk  : in  std_logic;
      ac97_reset   : out std_logic;
      --
      ready        : out std_logic;
      L_o          : in  std_logic_vector(17 downto 00);
      R_o          : in  std_logic_vector(17 downto 00);
      L_i          : out std_logic_vector(17 downto 00);
      R_i          : out std_logic_vector(17 downto 00);
      cmd_addr     : in  std_logic_vector(07 downto 00);
      cmd_data     : in  std_logic_vector(15 downto 00));
  end component;

  component dc97cmd 
    port (
      clk      : in  std_logic;
      ready    : in  std_logic;
      cmd_addr : out std_logic_vector(07 downto 00);
      cmd_data : out std_logic_vector(15 downto 00);
      volume   : in  std_logic_vector(04 downto 00);
      source   : in  std_logic_vector(02 downto 00));
    end component;
  
end pkg_dc97;

package body pkg_dc97 is
end pkg_dc97;


---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity dc97 is
  port (
    n_reset      : in  std_logic;
    clk          : in  std_logic;
    -- ac97 interface signals
    ac97_sdata_o : out std_logic;
    ac97_sdata_i : in  std_logic;
    ac97_sync    : out std_logic;
    ac97_bitclk  : in  std_logic;
    ac97_reset   : out std_logic;
    --
    ready        : out std_logic; -- one-cycle pulse
    L_o          : in  std_logic_vector(17 downto 00);
    R_o          : in  std_logic_vector(17 downto 00);
    L_i          : out std_logic_vector(17 downto 00);
    R_i          : out std_logic_vector(17 downto 00);
    cmd_addr     : in  std_logic_vector(07 downto 00);
    cmd_data     : in  std_logic_vector(15 downto 00));
end dc97;


architecture dc97_arch of dc97 is

  signal ed1_q        : std_logic;
  signal ed2_q        : std_logic;
  signal bit_count    : natural range 0 to 0255;
  signal ctrwait      : natural range 0 to 2047;
  signal dc97_ready   : std_logic;
  signal l_cmd_addr   : std_logic_vector(19 downto 00);
  signal l_cmd_data   : std_logic_vector(19 downto 00);
  signal l_cmd_v      : std_logic;
  signal l_left_data  : std_logic_vector(19 downto 00);
  signal l_right_data : std_logic_vector(19 downto 00);

  signal left_data     : std_logic_vector(19 downto 00);
  signal right_data    : std_logic_vector(19 downto 00);
  signal left_in_data  : std_logic_vector(19 downto 00);
  signal right_in_data : std_logic_vector(19 downto 00);
  
begin

  -- 20-bit <---> 16-bit conversion
  left_data  <= L_o & "00";
  right_data <= R_o & "00";

  L_i <= left_in_data(19 downto 2);
  R_i <= right_in_data(19 downto 2);

  -- Clock divider, clk = clk27MHz
  process (clk, n_reset)
  begin
    if rising_edge(clk) then
  		if n_reset = '0' then
  			ctrwait <= 0;
  			ac97_reset <= '0';
  		elsif ctrwait = 2047 then
  			ac97_reset <= '1';
  		else
  			ctrwait <= ctrwait + 1;
  		end if;
    end if;
  end process;

  l_cmd_v <= '1';

  -- basic di/assembly of ac97-link frames
  -- [ slot00 slot01 slot02 ..... slot12 ]

  -- outgoing ac97-link frame
  process (ac97_bitclk)
  begin
    
    if rising_edge(ac97_bitclk) then
      -- Generate the ac97 sync signal      
      if bit_count = 255 then
        ac97_sync <= '1';
      end if;

      if bit_count = 015 then
        ac97_sync <= '0';
      end if;

      -- Generate the ready signal
      if bit_count = 128 then
        dc97_ready <= '1';
      end if;

      if bit_count = 2 then
        dc97_ready <= '0';
      end if;

      -- Latch user data at the end of each frame. This ensures that the
      -- first frame after reset will be empty.
      if bit_count = 255 then
        l_cmd_addr   <= cmd_addr & "000000000000";
        l_cmd_data   <= cmd_data & "0000";
        l_left_data  <= left_data;
        l_right_data <= right_data;
      end if;

      if (bit_count >= 0) and (bit_count <= 15) then
        -- Slot 0 : Tags
        case bit_count is
          when 0      => ac97_sdata_o <= '1';      -- Frame valid
          when 1      => ac97_sdata_o <= l_cmd_v;  -- Command address valid
          when 2      => ac97_sdata_o <= l_cmd_v;  -- Command data valid
          when 3      => ac97_sdata_o <= '1';      -- left data valid
          when 4      => ac97_sdata_o <= '1';      -- right data valid
          when others => ac97_sdata_o <= '0';
        end case;
        
      elsif (bit_count >= 16) and (bit_count <= 35) then
        -- Slot 1 : Command address (8-bits, left justified)
        if l_cmd_v = '1' then
          ac97_sdata_o <= l_cmd_addr(35 - bit_count);
        else
          ac97_sdata_o <= '0';
        end if;

      elsif (bit_count >= 36) and (bit_count <= 55) then
        -- Slot 2 : Command data (16-bits, left justified)
        if l_cmd_v = '1' then
          ac97_sdata_o <= l_cmd_data(55 - bit_count);
        else
          ac97_sdata_o <= '0';
        end if;

      elsif ((bit_count >= 56) and (bit_count <= 75)) then

        -- Slot 3 : left channel
        ac97_sdata_o <= l_left_data(19);

        l_left_data <= l_left_data(18 downto 0) & l_left_data(19);

      elsif ((bit_count >= 76) and (bit_count <= 95)) then
        -- Slot 4 : right channel
        ac97_sdata_o <= l_right_data(95-bit_count);
        
      else
        ac97_sdata_o <= '0';
      end if;


      bit_count <= bit_count + 1;
    end if;
  end process;

  -- incoming ac97-link frame
  process (ac97_bitclk)
  begin
    if falling_edge(ac97_bitclk) then
      if (bit_count >= 57) and (bit_count <= 76) then
        -- Slot 3 : left channel
        left_in_data <= left_in_data(18 downto 0) & ac97_sdata_i;
      elsif (bit_count >= 77) and (bit_count <= 96) then
        -- Slot 4 : right channel
        right_in_data <= right_in_data(18 downto 0) & ac97_sdata_i;
      end if;
    end if;
  end process;

  -- rising-edge detector (one-cycle clk pulse)
  ed1_q <= '0' when n_reset = '0' else dc97_ready when rising_edge(clk);
  ed2_q <= '0' when n_reset = '0' else ed1_q when rising_edge(clk);
  ready <= (not ed1_q) and ed2_q;

end dc97_arch;

---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity dc97cmd is
  port (
    clk      : in  std_logic;
    ready    : in  std_logic;
    cmd_addr : out std_logic_vector(07 downto 00);
    cmd_data : out std_logic_vector(15 downto 00);
    volume   : in  std_logic_vector(04 downto 00);  -- 01000
    source   : in  std_logic_vector(02 downto 00)); --000 = Mic, 100=LineIn
end dc97cmd;



architecture dc97cmd_arch of dc97cmd is
  signal cmd   : std_logic_vector(23 downto 00);  
  signal atn   : std_logic_vector(04 downto 00);
  signal state : natural range 0 to 15;
  
begin

  cmd_addr <= cmd(23 downto 16);
  cmd_data <= cmd(15 downto 00);
  atn      <= 31 - volume;              -- convert to attenuation

  process (clk)
  begin
    if rising_edge(clk) then
      
      if ready = '1' then
        state <= state + 1;
      end if;

      case state is
        when 0     => cmd <= X"80_0000";  -- Read ID
        when 1     => cmd <= X"80_0000";  -- Read ID
        when 3     => cmd <= X"04" & "000" & atn & "000" & atn;  -- headphone volume
        when 5     => cmd <= X"18_0808";  -- PCM volume
        when 6     => cmd <= X"1A" & "00000" & source & "00000" & source;  -- Record source select
        when 7     => cmd <= X"1C_0F0F";  -- Record gain = max
        when 9     => cmd <= X"0E_8048";  -- set +20db mic gain
        when 10     => cmd <= X"0A_0000";  -- Set beep volume
        when 11     => cmd <= X"20_8000";  -- PCM out bypass mix1
        when others => cmd <= X"80_0000";
      end case;
    end if;
    
  end process;

end dc97cmd_arch;







