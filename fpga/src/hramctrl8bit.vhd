--
-- ZX Spectrum 48 8 bit hyperram controller
--
--
-- Copyright (c) 2016-2017 Jozsef Laszlo (rbendr@gmail.com)
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

entity hramctrl8bit is
  port ( 
    clk     : in std_logic; -- system clock, 27M for TangNano9K
    res     : in std_logic; -- active L !
    clk2x   : in std_logic;
    clk2xps : in std_logic;
    clk1x   : in std_logic;
    lock    : in std_logic;

    a       : in std_logic_vector(23 downto 0);  -- byte address, 16M space
    din     : in std_logic_vector(7 downto 0);
    dout    : out std_logic_vector(7 downto 0);
    wr      : in std_logic;                      -- active L, Z80 MEM WRITE
    rd      : in std_logic;                      -- active L, Z80 MEM WEAD
    stall   : out std_logic;                     -- active L, e.g. connect to Z80 WAIT line

    -- to HYPERRAM phy / GW1NR-9C
    O_psram_ck: out std_logic_vector(1 downto 0);
    O_psram_ck_n: out std_logic_vector(1 downto 0);
    IO_psram_dq: inout std_logic_vector(15 downto 0);
    IO_psram_rwds: inout std_logic_vector(1 downto 0);
    O_psram_cs_n: out std_logic_vector(1 downto 0);
    O_psram_reset_n: out std_logic_vector(1 downto 0)

  );
end hramctrl8bit;

architecture Behavioral of hramctrl8bit is

--signal lock : std_logic;
--signal clk200,clk200d,clk100 : std_logic;
alias clk200 : std_logic is clk2x;
alias clk200d : std_logic is clk2xps;
alias clk100 : std_logic is clk1x;

signal avm_write           : std_logic;
signal avm_read            : std_logic;
signal avm_address         : std_logic_vector(31 downto 0);
signal avm_writedata       : std_logic_vector(15 downto 0);
signal avm_byteenable      : std_logic_vector(1 downto 0) := "11";
signal avm_burstcount      : std_logic_vector(7 downto 0) := x"01";
signal avm_readdata        : std_logic_vector(15 downto 0);
signal avm_readdatavalid   : std_logic;
signal avm_waitrequest     : std_logic;

      -- HyperRAM device interface
signal hr_resetn_o         : std_logic;
signal hr_csn_o            : std_logic;
signal hr_ck_o             : std_logic;
signal hr_rwds_in          : std_logic;
signal hr_rwds_out         : std_logic;
signal hr_rwds_oe          : std_logic;   -- Output enable for RWDS
signal hr_dq_in            : std_logic_vector(7 downto 0);
signal hr_dq_out           : std_logic_vector(7 downto 0);
signal hr_dq_oe            : std_logic;    -- Output enable for DQ

signal r_stall : std_logic;
signal rdr,wrr : std_logic;
signal ctr : integer;
signal wcyc,rcyc : std_logic;
signal rdata : std_logic_vector(15 downto 0);
signal gres : std_logic;

begin

gres <= res and lock;

hram: entity work.hyperram 
   port map (
      clk_x1_i            => clk100,
      clk_x2_i            => clk200,
      clk_x2_del_i        => clk200d,
      rst_i               => not gres,

      -- Avalon Memory Map
      avm_write_i         => avm_write,
      avm_read_i          => avm_read,
      avm_address_i       => avm_address,
      avm_writedata_i     => avm_writedata,
      avm_byteenable_i    => avm_byteenable,
      avm_burstcount_i    => avm_burstcount,
      avm_readdata_o      => avm_readdata,
      avm_readdatavalid_o => avm_readdatavalid,
      avm_waitrequest_o   => avm_waitrequest,

      -- HyperRAM device interface
      hr_resetn_o         =>hr_resetn_o,
      hr_csn_o            =>hr_csn_o,
      hr_ck_o             =>hr_ck_o,
      hr_rwds_in_i        =>hr_rwds_in,
      hr_rwds_out_o       =>hr_rwds_out,
      hr_rwds_oe_o        =>hr_rwds_oe,
      hr_dq_in_i          =>hr_dq_in,
      hr_dq_out_o         =>hr_dq_out,
      hr_dq_oe_o          =>hr_dq_oe
   );

   O_psram_ck <= hr_ck_o & hr_ck_o;
   O_psram_ck_n <= "00";
   O_psram_cs_n <= hr_csn_o & hr_csn_o;
   O_psram_reset_n  <= hr_resetn_o & hr_resetn_o;
   IO_psram_rwds <= hr_rwds_out & hr_rwds_out when hr_rwds_oe = '1' else "ZZ";
   IO_psram_dq  <= hr_dq_out & hr_dq_out when hr_dq_oe   = '1' else (others => 'Z');
   hr_rwds_in <= IO_psram_rwds(0);
   hr_dq_in   <= IO_psram_dq(7 downto 0);

--avm_address <= "000000000" & a(23 downto 1); -- ctrl uses word address, a0 selects H/L byte
avm_address <= "00000000" & a(23 downto 0);
avm_writedata <= din & din;
--avm_byteenable <= "01" when a(0)='0' else "10";
avm_byteenable <= "11";

process (clk100,gres,wr,rd)
begin

  if gres='0' then
    r_stall <= '1';
    rcyc <= '0';
  elsif rising_edge(clk100) then
   
    rdr <= rd;
    wrr <= wr;

    avm_write <= '0';
    avm_read <= '0';

    if wrr='1' and wr='0' then
       avm_write <= '1';
    end if;

    if rdr='1' and rd='0' then
       avm_read <= '1';
       r_stall <= '0';
       rcyc <= '1';         
    end if;
 
    if rcyc='1' and avm_readdatavalid='1' then
       rcyc <= '0';
       r_stall <= '1';
       --rdata <= avm_readdata;
       dout <= avm_readdata(7 downto 0);
    end if;
   
  end if;

end process;

 --dout <= rdata(7 downto 0) when a(0)='0' else rdata(15 downto 8);
stall <= r_stall and (not avm_waitrequest); -- CPU must wait if stall='0'

end Behavioral;
