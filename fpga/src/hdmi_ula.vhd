--
-- ZX Spectrum 48 HDMI compatible ULA 
--
--
-- Copyright (c) 2016-2024 Jozsef Laszlo (rbendr@gmail.com)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity hdmi_ula is
    Port (
           RES_N : in  STD_LOGIC; 
	       CLKPX : in  STD_LOGIC; --  27M for 720x576 standard HDMI PAL res
          CPUCLK : in  STD_LOGIC; -- 3.5M  
            HCTR : in  STD_LOGIC_VECTOR (9 downto 0);
            VCTR : in  STD_LOGIC_VECTOR (9 downto 0);
               A : in  STD_LOGIC_VECTOR (15 downto 0);
             DIN : in  STD_LOGIC_VECTOR (7 downto 0);
            DOUT : out STD_LOGIC_VECTOR (7 downto 0);
            MREQ : in  STD_LOGIC;
            IORQ : in  STD_LOGIC;
              RD : in  STD_LOGIC;
              WR : in  STD_LOGIC;
             IRQ : out STD_LOGIC;
          CLKDIS : out STD_LOGIC;
          AUDIOL : out STD_LOGIC_VECTOR (15 downto 0);
          AUDIOR : out STD_LOGIC_VECTOR (15 downto 0);
   	    EXTKBCOL : in  STD_LOGIC_VECTOR (4 downto 0);
             RGB : out STD_LOGIC_VECTOR (23 downto 0)
);

end hdmi_ula;

architecture Behavioral of hdmi_ula is

constant H_START : integer := 104;
constant V_START : integer := 84;

type rgbpal is array(0 to 15) of std_logic_vector(7 downto 0);

signal pal_g : rgbpal :=
 (x"00",x"00",x"00",x"00",x"a0",x"a0",x"a0",x"a0",x"00",x"00",x"00",x"00",x"ff",x"ff",x"ff",x"ff");
signal pal_r : rgbpal :=
 (x"00",x"00",x"a0",x"a0",x"00",x"00",x"a0",x"a0",x"00",x"00",x"ff",x"ff",x"00",x"00",x"ff",x"ff");
signal pal_b : rgbpal :=
 (x"00",x"a0",x"00",x"a0",x"00",x"a0",x"00",x"a0",x"00",x"ff",x"00",x"ff",x"00",x"ff",x"00",x"ff");


type zxscreenmem is array(0 to 6143) of std_logic_vector(7 downto 0);
type zxcolormem  is array(0 to 2047) of std_logic_vector(7 downto 0);

alias ah : std_logic_vector(7 downto 0) is a(15 downto 8);
alias al : std_logic_vector(7 downto 0) is a( 7 downto 0);

signal zxscreen1 : zxscreenmem;
signal zxscreen2 : zxscreenmem;
signal zxcolor1 : zxcolormem;
signal zxcolor2 : zxcolormem;

signal zxs1,zxs2,zxa1,zxa2 : std_logic_vector(7 downto 0);
signal zxs1r,zxs2r,zxa1r,zxa2r : std_logic_vector(7 downto 0);
signal s0d,a0d,s1d,a1d : std_logic_vector(7 downto 0);
signal zxsceenaddr : std_logic_vector(12 downto 0); -- 8k
signal zxcoloraddr : std_logic_vector(9 downto 0); -- 1k

signal zxvpos : std_logic_vector(2 downto 0); -- line pos in a chr 0..7
signal zxhpos : std_logic_vector(2 downto 0); -- pixel pos in a chr 0..7
signal zxvaHoriz : std_logic_vector(4 downto 0); -- horizontal column pos 0..31
signal zxvaVert : std_logic_vector(4 downto 0); -- vertical char pos 0..23
signal zxpixel : std_logic_vector(3 downto 0); 
signal zxflashctr : std_logic_vector(6 downto 0); 
signal zxmcpair : std_logic_vector(1 downto 0); 
signal s0acc,a0acc,s1acc,a1acc : std_logic;

--signal hctr : std_logic_vector(9 downto 0);
--signal vctr : std_logic_vector(9 downto 0);
signal hstart : std_logic_vector(10 downto 0) := conv_std_logic_vector(H_START,11);
signal vstart : std_logic_vector(9 downto 0) := conv_std_logic_vector(V_START,10);
signal scrnhact : std_logic;
signal scrnvact : std_logic;
signal scrnact  : std_logic;
--signal hpos : std_logic_vector(10 downto 0);
--signal vpos : std_logic_vector(9 downto 0);

signal hclk : std_logic; -- half pixel clock for spectrum pixels
signal rgbi,ink,paper,border,pixel : std_logic_vector(3 downto 0);
signal vconf : std_logic_vector(7 downto 0);
signal rspk : std_logic;
signal rgbr : std_logic_vector(23 downto 0);
signal memw,iow,memr,ior : std_logic;

signal vacc : std_logic;

begin

memw <= mreq or wr;
iow  <= iorq or wr;
memr <= mreq or rd;
ior  <= iorq or rd;

-- contended memory simulation 
--vacc <= '1' when mreq='0' and A(15 downto 14)="10" and scrnact='1' and zxhpos<4 else '0';
--CLKDIS <= vacc;
CLKDIS <= '0';


process(CLKPX)
begin
  if rising_edge(CLKPX) then
    hclk <= not hclk;
  end if;		
end process;

process(RES_N,CLKPX)
begin
  if RES_N='0' then 
    --hctr <= (others=>'0');
    --vctr <= (others=>'0');
  elsif rising_edge(CLKPX) then
       if hctr=863 then 
          --hctr <= (others=>'0');
          if vctr=624 then
             --vctr <= (others=>'0');
             zxflashctr <= zxflashctr + 1;
          else
             --vctr <= vctr+1;
          end if;
        else
          --hctr <= hctr+1;		  
        end if;		
    end if;
end process;

process(CLKPX,hctr,vctr)
begin
  if rising_edge(CLKPX) then     
      if hctr>=hstart and hctr<hstart+512 then -- 256*2
        scrnhact <= '1';
      else
        scrnhact <= '0';
      end if;

      if vctr>=vstart and vctr<vstart+384 then  -- 192*2
        scrnvact <= '1';
      else
        scrnvact <= '0';
      end if;
     
     scrnact <= scrnhact and scrnvact;
     
     --hpos <= hctr-HSTART;
     --vpos <= vctr-VSTART;
  end if; 
end process;


zxsceenaddr <= zxvaVert(4 downto 3) & zxvpos & zxvaVert(2 downto 0) & zxvaHoriz;
zxcoloraddr <= zxvaVert & (zxvaHoriz);
zxmcpair <= zxs2r(7) & zxs1r(7);

s0acc <= '1' when ah>=x"40" and ah<=x"57" and mreq='0' else '0';
a0acc <= '1' when ah>=x"58" and ah<=x"5f" and mreq='0' else '0';
s1acc <= '1' when ah>=x"60" and ah<=x"77" and mreq='0' else '0';
a1acc <= '1' when ah>=x"78" and ah<=x"7f" and mreq='0' else '0';


process(RES_N,CPUCLK)
begin
 if RES_N='0' then
    ink <= "0111";
	paper <= "0000";
	border <= "0001";
    vconf <= x"00";
 else
  if rising_edge(CPUCLK) and iow='0' then    
    if a(0)='0' then
      border(2 downto 0) <= din(2 downto 0);
      rspk <= din(4);
    end if;
    if al=x"ef" then
      vconf <= din;
    end if;
  end if;  
 end if;
end process;

process(CPUCLK)
begin
  if rising_edge(CPUCLK) then
	 if memw='0' and s0acc='1' then
	   zxscreen1( conv_integer(a(12 downto 0))) <= din;
	 end if;
	 if memw='0' and a0acc='1' then
	   zxcolor1( conv_integer(a(10 downto 0))) <= din;
	 end if;
	 if memw='0' and s1acc='1' then
	   zxscreen2( conv_integer(a(12 downto 0))) <= din;
	 end if;
	 if memw='0' and a1acc='1' then
	   zxcolor2( conv_integer(a(10 downto 0))) <= din;
	 end if;
     s0d <= zxscreen1( conv_integer(a(12 downto 0)));
     a0d <= zxcolor1( conv_integer(a(10 downto 0)));
     s1d <= zxscreen2( conv_integer(a(12 downto 0)));
     a1d <= zxcolor2( conv_integer(a(10 downto 0)));
  end if;
end process;

DOUT <= s0d when s0acc='1' and memr='0' else
        a0d when a0acc='1' and memr='0' else
        s1d when s1acc='1' and memr='0' else
        a1d when a1acc='1' and memr='0' else
        "111" & EXTKBCOL when a(0)='0' and ior='0' else -- in fe
        x"ff";

process(hclk)
begin
  if rising_edge(hclk) then
     zxs1 <= zxscreen1( conv_integer(zxsceenaddr) );
	 zxs2 <= zxscreen2( conv_integer(zxsceenaddr+8192) );
     zxa1 <=  zxcolor1( conv_integer(zxcoloraddr));
	 zxa2 <=  zxcolor2( conv_integer(zxcoloraddr+8192) );	   
  end if;
end process;  

process(zxs1r,zxs2r,zxa1r,zxa2r,zxflashctr(5),vconf)
begin
    if vconf(3)='0' then
	   -- normal zx screen
		if (zxs1r(7) xor (zxflashctr(4) and zxa1r(7)))='1' then 
		  zxpixel <= zxa1r(6) & zxa1r(2 downto 0);
		else
		  zxpixel <= zxa1r(6 downto 3);
		end if;
	else
	   -- multicolor zx screen
		case zxmcpair is
		  when   "00" => zxpixel <= zxa1r(7 downto 4);
		  when   "01" => zxpixel <= zxa1r(3 downto 0);
		  when   "10" => zxpixel <= zxa2r(7 downto 4);
		  when others => zxpixel <= zxa2r(3 downto 0);
		end case;
	end if;
end process;

process(CLKPX)
begin
  if rising_edge(CLKPX) then   
    if scrnvact='1' then
      if scrnhact='1' then
        if hctr(0)='1' then 
           if zxhpos=7 then
              zxhpos <= "000";
              zxs1r <= zxs1; zxs2r <= zxs2; 
              zxa1r <= zxa1; zxa2r <= zxa2;
              zxvaHoriz <= zxvaHoriz+1;
            else
              zxs1r <= zxs1r(6 downto 0) & '0';
              zxs2r <= zxs2r(6 downto 0) & '0';
              zxhpos <= zxhpos+1; 
            end if;	  
        end if;
      else
         if hctr=hstart+512+2 and vctr(0)='1' then 
		  -- end of a scanline		  
		  if zxvpos=7 then
		     zxvpos <= "000";			 
			 zxvaVert <= zxvaVert+1;
		  else
 	       zxvpos <= zxvpos+1;
		  end if;		  
		end if;
      end if;
    else
 	  zxhpos <= "111";
	  zxvaHoriz <= "00000";
	  zxvaVert<= "00000";
      zxvpos <= "000";	
    end if;

  end if;
end process;

AUDIOL <= x"0000" when rspk='0' and vconf(7)='0' else x"1000";
AUDIOR <= x"0000" when rspk='0' and vconf(6)='0' else x"1000";

IRQ <= '0' when vctr=0 and hctr<128 and RES_N='1' else '1'; 

rgbi <= border when scrnact='0' else zxpixel;

process(CLKPX)
begin
  if rising_edge(CLKPX) then    
    rgbr <= pal_r(conv_integer(rgbi)) & pal_g(conv_integer(rgbi)) & pal_b(conv_integer(rgbi));  
  end if;
end process;

rgb <= '0' & rgbr(23 downto 17) & '0' & rgbr(15 downto 9) & '0' & rgbr(7 downto 1) when vctr(0)='1' and vconf(4)='1' else
       rgbr;

end Behavioral;