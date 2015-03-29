----------------------------------------------------------------------------------
-- VGA 640x480
-- http://tinyvga.com/vga-timing/640x480@60Hz
-- Because I slow down the addressing, each frame is read about 16 times.
-- This produces intensifies colours by 16. 
-- this results in a strectched 80 x 60 downscale into 480 x 640.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_driver is
  Port ( 
	 iVGA_CLK	    : in  STD_LOGIC;
	 r	    : out STD_LOGIC_VECTOR(3 downto 0);
	 g	    : out STD_LOGIC_VECTOR(3 downto 0);
	 b	    : out STD_LOGIC_VECTOR(3 downto 0);
	 hs	    : out STD_LOGIC;
	 vs	    : out STD_LOGIC;
	 surv : in std_logic;
	 debug : in natural;
	 debug2 : in natural;
	 buffer_addr : out STD_LOGIC_VECTOR(12 downto 0);
	 buffer_data : in  STD_LOGIC_VECTOR(15 downto 0);
	 motion : out natural
       );
end vga_driver;


architecture Behavioral of vga_driver is

  constant hRes       : natural := 640;
  constant vRes       : natural := 480;

  constant hMax  : natural := 799;
  constant hStartSync : natural := 656;
  constant hEndSync   : natural := 752;
  constant hsync_active : std_logic := '1';

  constant vMax  : natural := 524;
  constant vStartSync : natural := 490;
  constant vEndSync   : natural := 491;
  constant vsync_active : std_logic := '1';

  signal hCount : unsigned(9 downto 0) := (others => '0');
  signal vCount : unsigned(9 downto 0) := (others => '0');
  signal address : unsigned(16 downto 0) := (others => '0');
  signal blank : std_logic := '1';
  signal compare : 	 std_logic := '0';
begin
  buffer_addr <= std_logic_vector(address(15 downto 3)); 

  process(iVGA_CLK)
    variable r0    : unsigned (3 downto 0);
    variable g0	    :  unsigned (3 downto 0);
    variable b0	    :  unsigned (3 downto 0); 

  begin

    if rising_edge(iVGA_CLK) then
      if surv = '0' then
	if hCount = hMax then
	  hCount <= (others => '0');
	  if vCount = vMax then
	    vCount <= (others => '0');
	  else
	    vCount <= vCount+1;
	  end if;
	else
	  hCount <= hCount+1;
	end if;

	if blank = '0' then 
	  g  <= buffer_data(15 downto 12);
	  r  <= buffer_data(10 downto 7);
	  b  <= buffer_data(4 downto 1);
	else
	  r  <= (others => '0');
	  g  <= (others => '0');
	  b  <= (others => '0');
	end if;


	if vCount  >= vRes then
	  address <= (others => '0');
	  blank <= '1';
	else	
	  if hCount < hRes then
	    blank <= '0';
	    if hCount = hRes-1 then 
	      if vCount( 2 downto 0 ) /= "111" then
		address <= address - hRes +1; ---debug +debug2; -- I dont know why its 641 (/8 = 81). But it works.
	      else
		address <= address+1;
	      end if;
	    elsif vCount( 1 ) /= '1' then -- Blank every other
	      blank <='1';
	      address <= address+1;
	    else
	      address <= address+1;
	    end if;
	  else
	    blank <= '1';
	  end if;
	end if;

	if hCount >= hStartSync and hCount < hEndSync then
	  hs <= hsync_active;
	else
	  hs <= not hsync_active;
	end if;

	if vCount >= vStartSync and vCount < vEndSync then
	  vs <= vsync_active;
	else
	  vs <= not vsync_active;
	end if;

      else--	if surv = '1' then
	if hCount = hMax then
	  hCount <= (others => '0');
	  if vCount = vMax then
	    vCount <= (others => '0');
	  else
	    vCount <= vCount+1;
	  end if;
	else
	  hCount <= hCount+1;
	end if;

	if blank = '0' then 
	  if vCount < 320  then
	    if compare = '0' then
	      g0  := unsigned(buffer_data(15 downto 12));
	      r0  := unsigned(buffer_data(10 downto 7));
	      b0  := unsigned(buffer_data(4 downto 1));
	      g  <= buffer_data(15 downto 12);
	      r  <= buffer_data(10 downto 7);
	      b  <= buffer_data(4 downto 1);
	    else 
	      if (abs(to_integer(unsigned(buffer_data(10 downto 7))) - to_integer(r0)) +
	      abs(to_integer(unsigned(buffer_data(15 downto 12))) - to_integer(g0)) +
	      abs(to_integer(unsigned(buffer_data(4 downto 1))) - to_integer(b0))) 
	      > 20 then --+ debug - debug2 then
		g<= "1111";
		r<= "1111";
		b<= "1111";
	      else
		r  <= (others => '0');
		g  <= (others => '0');
		b  <= (others => '0');
	      end if;
	      motion <= natural(abs(to_integer(unsigned(buffer_data(10 downto 7))) - to_integer(r0)) +
			abs(to_integer(unsigned(buffer_data(15 downto 12))) - to_integer(g0)) +
			abs(to_integer(unsigned(buffer_data(4 downto 1))) - to_integer(b0)));
	    end if;
	  else
	    if compare = '0' then
	      g  <= buffer_data(15 downto 12);
	      r  <= buffer_data(10 downto 7);
	      b  <= buffer_data(4 downto 1);
	    else 
	      r  <= (others => '0');
	      g  <= (others => '0');
	      b  <= (others => '0');
	    end if;
	  end if;
	else
	  r   <= (others => '0');
	  g <= (others => '0');
	  b  <= (others => '0');
	end if;


	if vCount  >= vRes/2 then
	  address <= (others => '0');
	  blank <= '1';
	else	
	  if hCount < hRes then
	    blank <= '0';
	    if hCount = hRes-1 then 
	      if vCount( 2 downto 0 ) /= "111" then
		address <= address - hRes +1; --+1 for address, address 0 read already
	      else
		if compare = '0' then
		  address <= address+19208; -- 2400 * 8.		
		  compare <= '1';
		else
		  address <= address-19206;
		  compare <= '0';
		end if;
	      end if;
	    elsif vCount( 1 ) /= '1' then 
	      blank <='1';
	      address <= address+1;
	    else --Because this counts up to 640, then it gets subtracted. The compare flag should go in the top if statement
	      address <= address+1;
	    end if;
	  else
	    blank <= '1';
	  end if;
	end if;

	if hCount >= hStartSync and hCount < hEndSync then
	  hs <= hsync_active;
	else
	  hs <= not hsync_active;
	end if;

	if vCount >= vStartSync and vCount < vEndSync then
	  vs <= vsync_active;
	else
	  vs <= not vsync_active;
	end if;

      end if; -- end surv
    end if; -- end rising edge
  end process;
end Behavioral;
