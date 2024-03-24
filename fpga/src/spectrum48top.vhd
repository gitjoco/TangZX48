--
-- ZX Spectrum 48 - spectrum top level, without RAM
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

entity spectrum48top is
    Port ( CLK28IN : in  STD_LOGIC; 
           CLK27IN : in  STD_LOGIC;
          CLK135IN : in  STD_LOGIC;
	       RESETIN : in  STD_LOGIC; -- act H signal

            HCTRIN : in  STD_LOGIC_VECTOR (10 downto 0); -- counter come from hdmi module
            VCTRIN : in  STD_LOGIC_VECTOR ( 9 downto 0);

               RGB : out STD_LOGIC_VECTOR (23 downto 0); -- video output
             HSYNC : out STD_LOGIC;
             VSYNC : out STD_LOGIC;

            CPULCK : out STD_LOGIC;
           CPUSTOP : in  STD_LOGIC; -- act L signal, cpu stops being clocked when CPUSTOP='0'
            RESVEC : in  STD_LOGIC_VECTOR (15 downto 0);  -- vector for reset Z80
           CPUWAIT : in  STD_LOGIC; -- wired to cpu WAIT signal
            -- ram (upper 32k)
             XRAMA : out STD_LOGIC_VECTOR (23 downto 0);
            XRAMDO : in  STD_LOGIC_VECTOR (7 downto 0);
            XRAMDI : out STD_LOGIC_VECTOR (7 downto 0);
            XRAMWR : out STD_LOGIC;
            XRAMRD : out STD_LOGIC;
            -- cmd io channel for mcu
               REQ : out STD_LOGIC;
               ACK : in STD_LOGIC;
              CCDO : out STD_LOGIC_VECTOR (7 downto 0);
              CCDI : in STD_LOGIC_VECTOR (7 downto 0);

            PS2CLK : in  STD_LOGIC;
            PS2DAT : in  STD_LOGIC;
             JOYIN : in STD_LOGIC_VECTOR (4 downto 0);

            AUDIOL : out STD_LOGIC_VECTOR (15 downto 0);
		    AUDIOR : out STD_LOGIC_VECTOR (15 downto 0)
);
			 
end spectrum48top;

architecture Behavioral of spectrum48top is

signal Clk28 : std_logic;
signal cpuclk,cpuint,cpumreq,cpuiorq,cpurd,cpuwr,cpurfsh,cpum1 : std_logic;
signal cpud,cpudi,cpudo,viddi,viddo,ulado : std_logic_vector(7 downto 0);
signal cpua : std_logic_vector(15 downto 0);
signal vida : std_logic_vector(13 downto 0);
signal ramcs,ramwr,ramrd,romoe,vidwr,vidrd,vidcs : std_logic;
signal ulargb : std_logic_vector(3 downto 0);
signal kbrow : std_logic_vector(7 downto 0);
signal ps2kbcol : std_logic_vector(4 downto 0);
signal romdo : std_logic_vector(7 downto 0);
signal kbcol : std_logic_vector(4 downto 0) := "11111" ;
signal rgbout : std_logic_vector(11 downto 0);
signal mic,spk,c_sync,h_sync,v_sync : std_logic;

signal resctr : std_logic_vector(31 downto 0) := x"00000000";
signal cpures,ps2res : std_logic;
signal iord,iowr,spiw,spir,spiact : std_logic;
signal romwr : std_logic;
signal spkr,dacout : std_logic;
signal spkr_val : std_logic_vector(7 downto 0);

signal hctr,vctr : std_logic_vector(8 downto 0);
signal palblank,ulablank,vgablank,vgahs,vgavs : std_logic;
signal palin,vgargb : std_logic_vector(3 downto 0);

signal ramdo : std_logic_vector(7 downto 0);

signal req_r : std_logic;
signal clk28div : std_logic_vector(2 downto 0); -- 14 7 3.5

signal  waitp : std_logic_vector(3 downto 0) := "1111";
signal vidacc : std_logic;
signal   cclk : std_logic;


begin
  
  Clk28 <= CLK28IN;
  
  cpures <= not RESETIN;
  
  process(Clk28)
  begin
   if rising_edge(Clk28) then	  
	  clk28div <= clk28div-1;
	end if;
  end process;

  rom : entity work.rom16k
    port map ( 
	 CLK => Clk28,
       A => cpua(13 downto 0),
    DOUT => romdo,
	 DIN => cpudo,
	  WR => romwr	  
	 );
 
  -- 14M
  process(clk28div(1)) 
  begin
    if rising_edge(clk28div(1)) then
      --if vidacc='0' and cpuclk='1' and CPUWAIT='1' then
      if vidacc='0' and cpuclk='1' then
        cpuclk <= '0';
      else 
        cpuclk <= '1';
      end if;
    end if;
  end process;

  z80cpu : entity work.t80a
  	port map (
		RESET_n => cpures and ps2res,
        RESVEC  => RESVEC,
		CLK_n	=> cpuclk,-- or (not CPUWAIT), --cpuclk,-- or (not CPUSTOP),
		WAIT_n =>  '1',
		INT_n	=> cpuint,
		NMI_n	=> '1',
		BUSRQ_n => '1',	
		M1_n => cpum1,		
		MREQ_n => cpumreq,	
		IORQ_n => cpuiorq,	
		RD_n => cpurd,		
		WR_n => cpuwr,
		RFSH_n => cpurfsh,	
		HALT_n => open,	
		BUSAK_n => open,	
		A	=> cpua,
		DIN	 => cpudi,
        DOUT => cpudo
	);
	 
   ps2kbd : entity work.zxps2kbd
    port map ( 
	  CLK28M => clk28div(0),
	   RESET => not cpures,
 	   KBCLK => PS2CLK,
       KBDAT => PS2DAT, 		   		
	  RESOUT =>	ps2res,	 	
	       A => cpua,
	      DO => ps2kbcol,
	  	  RD => cpurd,
 	    IORQ => cpuiorq
		 );
		 
  ula : entity work.hdmi_ula 
    Port map (
           RES_N => cpures,
	       CLKPX => CLK27IN,
          CPUCLK => cpuclk,
            HCTR => hctrin(9 downto 0),
            VCTR => vctrin,
          CLKDIS => vidacc,
               A => cpua,
             DIN => cpudo,
            DOUT => ulado,
            MREQ => cpumreq,
            IORQ => cpuiorq,
              RD => cpurd,
              WR => cpuwr,
             IRQ => cpuint,
          AUDIOL => AUDIOL,
          AUDIOR => AUDIOR,
   	    EXTKBCOL => ps2kbcol,
             RGB => RGB
);
  
  iord <= cpurd or cpuiorq or (not cpum1);
  iowr <= cpuwr or cpuiorq;

  -- 04b0 .. 04bf: a ram window in rom space, helps loading .sna files
  romwr <= '1' when cpua(15 downto 4)=x"04b" and cpumreq='0' and cpuwr='0' else '0';
  -- rom space 0000..3fff
  romoe <= '0' when cpua(15 downto 14)="00" and cpumreq='0' and cpurd='0' else '1'; 
  -- upper ram 
  ramcs <= '0' when cpua(15)='1' and cpumreq='0' else '1'; 
   
  
  cpudi <= ulado when (cpua(15 downto 14)="01" and cpumreq='0' and cpurd='0') or -- videoram
                      (cpuiorq='0' and cpua(0)='0' and cpurd='0') else		     -- ula port fe			   
					  ramdo when (ramcs='0' and cpurd='0') else                  -- ram data 
					  romdo when romoe='0' else                                  -- rom data
                      CCDI when iord='0' and cpua(7 downto 0)=x"f7" else         -- m1 mpu dout
                      ACK & "000000" & req_r when iord='0' and cpua(7 downto 0)=x"ef" else      -- m1 mpu status/wait signal`
					  "000" & (not JOYIN) when cpua(7 downto 0)=x"1f" and iord='0' else -- kempston joy 
                      "11111111"; 
    
  -- external psram/hyperram signals, ram ctrl implemented in toplevel
  XRAMA <= x"00" & cpua;
  ramdo <= XRAMDO;
 XRAMDI <= cpudo;
 XRAMWR <= ramcs or cpuwr;
 XRAMRD <= ramcs or cpurd;

 --  RGB <= rgbout(11 downto 9) & "0000" & rgbout(8 downto 4) & "0000" & rgbout(3 downto 0) & "0000" ;
  HSYNC <= vgahs;
  VSYNC <= vgavs;

 -- handshake communication with m1 mpu, ports: f7 - data, ef - status
 process (cpuClk,ACK,cpures)
 begin
   if ACK='1' or cpures='0' then
     req_r <= '0';    
   else	
     if rising_edge(iowr) and cpua(7 downto 0)=x"f7" then 
        CCDO <= cpudo;
        req_r <= '1';    
     end if;
   end if;
 end process;

REQ <= req_r;

end Behavioral;

