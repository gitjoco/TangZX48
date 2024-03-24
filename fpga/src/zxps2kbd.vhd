--
-- ZX Spectrum 48 - PS2 keyboard interface
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

entity zxps2kbd is
    Port ( 
	  CLK28M : in  STD_LOGIC;
	   RESET : in  STD_LOGIC;
 	   KBCLK : in  STD_LOGIC;
       KBDAT : in  STD_LOGIC;
		   		 
	  RESOUT : out STD_LOGIC;
	       A : in  STD_LOGIC_VECTOR(15 downto 0);		  
	      DO : out STD_LOGIC_VECTOR(4 downto 0);
		  RD : in  STD_LOGIC;	
 	    IORQ : in  STD_LOGIC);
			  
end zxps2kbd;

architecture Behavioral of zxps2kbd is

type   ctable is array(0 to 127) of std_logic_vector(7 downto 0);

type    kbits is array(0 to 7) of std_logic_vector(4 downto 0);

signal kbdsign : std_logic;
signal kbddata : std_logic_vector(7 downto 0);


signal keypress : std_logic:='0';
signal shiftreg : std_logic_vector(10 downto 1) :="1111111111";
signal counter  : std_logic_vector(3 downto 0);

signal cpures : std_logic:='1';

signal dOut  : std_logic_vector(4 downto 0);
signal keybits : kbits := (others=>"11111");
signal lastkc : std_logic;

--      IN:    Reads keys (bit 0 to bit 4 inclusive, in that order)
--      bit#   0   1   2   3   4              0   1   2   3   4
--      #FEFE CSH, Z,  X,  C,  V       #EFFE  0,  9,  8,  7,  6
--      #FDFE  A,  S,  D,  F,  G       #DFFE  P,  O,  I,  U,  Y
--      #FBFE  Q,  W,  E,  R,  T       #BFFE  ENT,L,  K,  J,  H
--      #F7FE  1,  2,  3,  4,  5       #7FFE  SP,SYS, M,  N,  B


-----------------------------
--  7     6    5-4-3  2-1-0
-- syms capss bitnum bytenum
-----------------------------
signal convtab  : ctable := (
 x"FF",  -- 00
 x"FF",  -- 01  F9
 x"FF",  -- 02
 x"FF",  -- 03  F5
 "01001100",  -- 04  F3  (GRAPH, CapsShift-9)   
 "01010011",  -- 05  F1  (Norm video, CapsShift-3)
 "01011011",  -- 06  F2  (Inv. video, CapsShift-4)
 x"FF",  -- 07  F12
 x"FF",  -- 08
 x"FF",  -- 09  
 x"FF",  -- 0a  F8
 x"FF",  -- 0b  F6
 x"FF",  -- 0c  F4
 "01000011",  -- 0d  tab (EDIT CS+1)
 x"FF",  -- 0e  
 x"FF",  -- 0f  

 x"FF",  -- 10
 "11000000",  -- 11  alt (EXT mode)
 "00000000",  -- 12  left-shift  (CAPS SHIFT)
 x"FF",  -- 13  
 "00001111",  -- 14  ctrl (SYMBOL SHIFT)
 "00000010",  -- 15  Q
 "00000011",  -- 16  1/!
 x"FF",  -- 17  
 x"FF",  -- 18
 x"FF",  -- 19  
 "00001000",  -- 1a  Z 
 "00001001",  -- 1b  S
 "00000001",  -- 1c  A
 "00001010",  -- 1d  W
 "00001011",  -- 1e  2/@
 x"FF",  -- 1f  

 x"FF",  -- 20
 "00011000",  -- 21  C
 "00010000",  -- 22  X
 "00010001",  -- 23  D
 "00010010",  -- 24  E
 "00011011",  -- 25  4/$
 "00010011",  -- 26  3/#
 x"FF",  -- 27  
 x"FF",  -- 28
 "00000111",  -- 29  space
 "00100000",  -- 2a  V 
 "00011001",  -- 2b  F
 "00100010",  -- 2c  T
 "00011010",  -- 2d  R
 "00100011",  -- 2e  5/%
 x"FF",  -- 2f  

 x"FF",  -- 30
 "00011111",  -- 31  N
 "00100111",  -- 32  B
 "00100110",  -- 33  H
 "00100001",  -- 34  G
 "00100101",  -- 35  Y
 "00100100",  -- 36  6/^
 x"FF",  -- 37  
 x"FF",  -- 38
 x"FF",  -- 39  
 "00010111",  -- 3a  M 
 "00011110",  -- 3b  J
 "00011101",  -- 3c  U
 "00011100",  -- 3d  7/&
 "00010100",  -- 3e  8/*
 x"FF",  -- 3f  

 x"FF",  -- 40
 "10011111",  -- 41  ,/<  (,  SymShift-N)
 "00010110",  -- 42  K
 "00010101",  -- 43  I
 "00001101",  -- 44  O
 "00000100",  -- 45  0/)
 "00001100",  -- 46  9/(
 x"FF",  -- 47  
 x"FF",  -- 48
 "10010111",  -- 49  >/.  (. SymShift-M)
 "10100000",  -- 4a  //?  (/ SymShift-V)
 "00001110",  -- 4b  L
 "10001000",  -- 4c  ;/: (: SymShift-Z)
 "00000101",  -- 4d  P
 "10011110",  -- 4e  -/_ (- SymShift-J)
 x"FF",  -- 4f  

 x"FF",  -- 50
 x"FF",  -- 51  
 "10000101",  -- 52  '/" (" SymShift-P)
 x"FF",  -- 53  
 x"FF",  -- 54  [/{
 "10001110",  -- 55  =/+ (= SymShift-L)
 x"FF",  -- 56  
 x"FF",  -- 57  
 "01001011",  -- 58  caps lock (Caps CapsShift-2)
 "00000000",  -- 59  right-shift
 "00000110",  -- 5a  enter 
 x"FF",  -- 5b  ]/}
 x"FF",  -- 5c  
 x"FF",  -- 5d  \/|
 x"FF",  -- 5e  
 x"FF",  -- 5f  

 x"FF",  -- 60
 x"FF",  -- 61  
 x"FF",  -- 62
 x"FF",  -- 63  
 x"FF",  -- 64  
 x"FF",  -- 65  
 "01000100",  -- 66  backspace (DELETE, CapsShift-0)
 x"FF",  -- 67  
 x"FF",  -- 68
 x"FF",  -- 69  
 x"FF",  -- 6a   
 "01100011",  -- 6b  crsr-right (CapsShift-8)
 x"FF",  -- 6c  
 x"FF",  -- 6d  
 x"FF",  -- 6e  
 x"FF",  -- 6f  

 x"FF",  -- 70
 x"FF",  -- 71  
 "01100100",  -- 72  crsr-down (CapsShift-6)
 x"FF",  -- 73  
 "01010100",  -- 74  crsr-left (CapsShift-5)
 "01011100",  -- 75  crsr-up (CapsShift-7)
 "01000111",  -- 76  ESC (CapsShift-Space: BREAK)
 x"FF",  -- 77  
 x"FF",  -- 78  F11
 x"FF",  -- 79  
 x"FF",  -- 7a   
 x"FF",  -- 7b  
 x"FF",  -- 7c  
 x"FF",  -- 7d  
 x"FF",  -- 7e  
 x"FF"   -- 7f  
 );

begin

  --iord <= RD or IORQ or (not M1) or (not CPUCLKEN);
  --iowr <= WR or IORQ or (not CPUCLKEN);
  --iowr2<= WR or IORQ;
  
  ps2rd : entity work.ps2reader
  port map (
	 mclk => CLK28M,
	 PS2C => KBCLK, 
	 PS2D => KBDAT,
	 rst => RESET,
	 Ps2Dout => kbddata,
	 fRd => kbdsign
  );

   
  process(RESET,kbdsign,kbddata)
  variable idx : integer range 0 to 127;
  variable cdt : std_logic_vector(7 downto 0);
  begin
   if RESET='1' then
	    keypress <= '0';
		keybits(0)<="11111";
		keybits(1)<="11111";
		keybits(2)<="11111";
		keybits(3)<="11111";		
		keybits(4)<="11111";
		keybits(5)<="11111";
		keybits(6)<="11111";
		keybits(7)<="11111";				
		cpures <= '1';
	else
	  if rising_edge(kbdsign) then
	  
		   if kbddata=x"07" and keypress='0' then -- F12 - CPU reset
			  cpures <= '0';			  
			else
			  cpures <= '1';
			end if;
	  
			if kbddata=x"F0" then
			  keypress <= '1'; 
			elsif kbddata=x"E0" then
			  null;
			else
			  keypress <= '0';
			  idx := conv_integer(kbddata(6 downto 0));
			  cdt := convtab(idx);
			  if convtab(idx)/=x"FF" then
				 keybits( conv_integer(cdt(2 downto 0)) )( conv_integer(cdt(5 downto 3)) ) <= keypress;
				 if cdt(7)='1' then -- symbol shift must be pressed

				   keybits(7)(1)<=keypress;
				 end if;
				 if cdt(6)='1' then -- caps shift must be pressed
				   keybits(0)(0)<=keypress;				 
				 end if;

			  end if;	  
			end if; 
     end if;	  
	end if;
  end process;
 

 process(CLK28M,A,RD,IORQ,keybits)
  variable sum: std_logic_vector(4 downto 0);
  begin
	if rising_edge(CLK28M) then
		if RD='0' and IORQ='0' then
		else
		  sum:="11111";
		  for i in 0 to 7 loop
			 if A(8+i)='0' then 
				sum:=sum and keybits(i);
			 end if;
		  end loop;
		end if;
		dOut<=sum;
   end if;
  end process;

 DO <= dOut when IORQ='0' and RD='0' and A(0)='0' else  -- in (FE)
		 "11111";
 
 RESOUT <= cpures;
 
end Behavioral;
