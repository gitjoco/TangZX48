--
-- ZX Spectrum 48 with HDMI video output for TANG NANO 9K board
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

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity toplevel is
    Port (    clk  : in  STD_LOGIC; -- main clk 17M
	          res  : in  STD_LOGIC; -- reset (act L)
		   ps2clk  : in  STD_LOGIC; -- keyboard
		   ps2dat  : in  STD_LOGIC;

        -- GW1NR-9C internal psram interface
        O_psram_ck: out std_logic_vector(1 downto 0);
		O_psram_ck_n: out std_logic_vector(1 downto 0);
		IO_psram_dq: inout std_logic_vector(15 downto 0);
		IO_psram_rwds: inout std_logic_vector(1 downto 0);
		O_psram_cs_n: out std_logic_vector(1 downto 0);
		O_psram_reset_n: out std_logic_vector(1 downto 0);

        
		   led : out  STD_LOGIC_VECTOR (4 downto 0);
		   rxd : in  STD_LOGIC; -- m1 mcu debug port
		   txd : out STD_LOGIC;			  			  

        -- digital joy
        joy : in std_logic_vector(4 downto 0);

        -- SPI to SD card
        sd_miso 	  : in  STD_LOGIC;
        sd_cs 		  : out STD_LOGIC;
        sd_mosi 	  : out STD_LOGIC;
        sd_sck 		  : out STD_LOGIC;

       -- HDMI output
	   tmds_clk_p  : out std_logic;
	   tmds_clk_n  : out std_logic;
		  tmds_d_p : out std_logic_vector(2 downto 0);
		  tmds_d_n : out std_logic_vector(2 downto 0)
          );
end toplevel;

architecture Behavioral of toplevel is

component hdmi
	port (
        clk_pixel_x5 : in std_logic;
        clk_pixel    : in std_logic;
        clk_audio    : in std_logic;
        reset        : in std_logic;
        rgb          : in std_logic_vector(23 downto 0);
        audio_l      : in std_logic_vector(15 downto 0);
        audio_r      : in std_logic_vector(15 downto 0);

        tmds_clk_n   : out std_logic;
        tmds_clk_p   : out std_logic;
        tmds_d_n     : out std_logic_vector(2 downto 0);
        tmds_d_p     : out std_logic_vector(2 downto 0);

        cx           : out std_logic_vector(11 downto 0); 
        cy           : out std_logic_vector( 9 downto 0); 
        frame_width  : out std_logic_vector(10 downto 0); 
        frame_height : out std_logic_vector( 9 downto 0); 
        screen_width : out std_logic_vector(10 downto 0); 
        screen_height: out std_logic_vector( 9 downto 0)
    );
end component;

component Gowin_EMPU_M1_Top
	port (
		LOCKUP: out std_logic;

		UART0RXD: in std_logic;
		UART0TXD: out std_logic;

		APB1PADDR: out std_logic_vector(31 downto 0);
		APB1PENABLE: out std_logic;
		APB1PWRITE: out std_logic;
		APB1PSTRB: out std_logic_vector(3 downto 0);
		APB1PPROT: out std_logic_vector(2 downto 0);
		APB1PWDATA: out std_logic_vector(31 downto 0);
		APB1PSEL: out std_logic;
		APB1PRDATA: in std_logic_vector(31 downto 0);
		APB1PREADY: in std_logic;
		APB1PSLVERR: in std_logic;
		APB1PCLK: out std_logic;
		APB1PRESET: out std_logic;

		EXTFLASH0HRDATA: in std_logic_vector(31 downto 0);
		EXTFLASH0HREADYOUT: in std_logic;
		EXTFLASH0HRESP: in std_logic_vector(1 downto 0);
		EXTFLASH0HTRANS: out std_logic_vector(1 downto 0);
		EXTFLASH0HBURST: out std_logic_vector(2 downto 0);
		EXTFLASH0HPROT: out std_logic_vector(3 downto 0);
		EXTFLASH0HSIZE: out std_logic_vector(2 downto 0);
		EXTFLASH0HWRITE: out std_logic;
		EXTFLASH0HREADYMUX: out std_logic;
		EXTFLASH0HMASTER: out std_logic_vector(3 downto 0);
		EXTFLASH0HMASTLOCK: out std_logic;
		EXTFLASH0HADDR: out std_logic_vector(31 downto 0);
		EXTFLASH0HWDATA: out std_logic_vector(31 downto 0);
		EXTFLASH0HSEL: out std_logic;
		EXTFLASH0HCLK: out std_logic;
		EXTFLASH0HRESET: out std_logic;

		MOSI: out std_logic;
		MISO: in std_logic;
		SCLK: out std_logic;
		NSS: out std_logic;

		HCLK: in std_logic;
		hwRstn: in std_logic
	);
end component;

component GW_FLASH 
  port (
    hclk                   : in std_logic;
    hresetn                : in std_logic;
    targflash0_hsel_i      : in std_logic;
    targflash0_haddr_i     : in std_logic_vector(31 downto 0);
    targflash0_htrans_i    : in std_logic_vector(1 downto 0);
    targflash0_hwrite_i    : in std_logic;
    targflash0_hsize_i     : in std_logic_vector(2 downto 0);
    targflash0_hburst_i    : in std_logic_vector(2 downto 0);
    targflash0_hprot_i     : in std_logic_vector(3 downto 0);
    targflash0_memattr_i   : in std_logic_vector(1 downto 0);
    targflash0_exreq_i     : in std_logic;
    targflash0_hmaster_i   : in std_logic_vector(3 downto 0);
    targflash0_hwdata_i    : in std_logic_vector(31 downto 0);
    targflash0_hmastlock_i : in std_logic;
    targflash0_hreadymux_i : in std_logic;
    targflash0_hauser_i    : in std_logic;
    targflash0_hwuser_i    : in std_logic_vector(3 downto 0);
    targflash0_hrdata_o    : out std_logic_vector(31 downto 0);
    targflash0_hreadyout_o : out std_logic;
    targflash0_hresp_o     : out std_logic;
    targflash0_exresp_o    : out std_logic;
    targflash0_hruser_o    : out std_logic_vector(1 downto 0);
    flash_err_o            : out std_logic;
    flash_int_o            : out std_logic;
    pclk                   : in  std_logic;
    pclkg                  : in  std_logic
);
end component;

component Gowin_rPLL135
    port (
        clkout: out std_logic;  -- 135M for HDMI (5x pixelclock)
        clkoutp: out std_logic; -- 135M phase shifted for hram (135deg) 
        lock: out std_logic;
        reset: in std_logic;
        clkin: in std_logic     -- 27M
    );
end component;

component Gowin_rPLL
    port (
         clkout: out std_logic;  -- 140
           lock: out std_logic;  
        clkoutp: out std_logic;  -- 140 phaseshift 135deg
        clkoutd: out std_logic;  -- 70
          reset: in std_logic;
          clkin: in std_logic    -- 135M phase shifted
    );
end component;

component Gowin_CLKDIV
    port (
        clkout: out std_logic;
        hclkin: in std_logic;
        resetn: in std_logic
    );
end component;

-- user flash signals for MCU code
signal EXTFLASH0HRDATA:  std_logic_vector(31 downto 0);
signal EXTFLASH0HREADYOUT:  std_logic;
signal EXTFLASH0HRESP:  std_logic_vector(1 downto 0);
signal EXTFLASH0HTRANS:  std_logic_vector(1 downto 0);
signal EXTFLASH0HBURST:  std_logic_vector(2 downto 0);
signal EXTFLASH0HPROT:  std_logic_vector(3 downto 0);
signal EXTFLASH0HSIZE:  std_logic_vector(2 downto 0);
signal EXTFLASH0HWRITE:  std_logic;
signal EXTFLASH0HREADYMUX:  std_logic;
signal EXTFLASH0HMASTER:  std_logic_vector(3 downto 0);
signal EXTFLASH0HMASTLOCK:  std_logic;
signal EXTFLASH0HADDR:  std_logic_vector(31 downto 0);
signal EXTFLASH0HWDATA:  std_logic_vector(31 downto 0);
signal EXTFLASH0HSEL:  std_logic;
signal EXTFLASH0HCLK:  std_logic;
signal EXTFLASH0HRESET:  std_logic;

-- Spectrum - M1 mcu communication via ABP1
signal APB1PADDR: std_logic_vector(31 downto 0);
signal APB1PENABLE: std_logic;
signal APB1PWRITE: std_logic;
signal APB1PSTRB: std_logic_vector(3 downto 0);
signal APB1PPROT: std_logic_vector(2 downto 0);
signal APB1PWDATA: std_logic_vector(31 downto 0);
signal APB1PSEL: std_logic;
signal APB1PRDATA: std_logic_vector(31 downto 0);
signal APB1PREADY: std_logic;
signal APB1PSLVERR: std_logic;
signal APB1PCLK: std_logic;
signal APB1PRESET: std_logic;

   signal clk135  : std_logic := '0';
   signal clk135p : std_logic := '0';
   signal lock135 : std_logic; 

   signal clk140  : std_logic := '0';
   signal clk140d : std_logic := '0';
   signal clk70   : std_logic := '0';
   signal clk28   : std_logic := '0';
   signal lock    : std_logic; 

   signal red     : std_logic_vector(7 downto 0) := (others => '0');
   signal green   : std_logic_vector(7 downto 0) := (others => '0');
   signal blue    : std_logic_vector(7 downto 0) := (others => '0');
   signal hsync   : std_logic := '0';
   signal vsync   : std_logic := '0';
   signal blank   : std_logic := '0';

-- hram signals
signal  xrama : STD_LOGIC_VECTOR (23 downto 0);
signal xramdo : STD_LOGIC_VECTOR (7 downto 0);
signal xramdi : STD_LOGIC_VECTOR (7 downto 0);
signal  xramw : STD_LOGIC;
signal  xramr : STD_LOGIC;
signal cpuwait : STD_LOGIC;
signal cpustop : STD_LOGIC := '1';
signal resvec : std_logic_vector(15 downto 0) := x"0000";
signal ramres : std_logic := '1';
signal  zxres : std_logic := '1';

signal zxrgb : std_logic_vector(23 downto 0); -- zx rgb video	
signal zxalf : std_logic_vector(15 downto 0); -- audio left	
signal zxarg : std_logic_vector(15 downto 0); -- audio right, same as left channel, mono now
signal clkAudio : std_logic;
signal aclkctr : integer range 0 to 1023;

-- mcu access to psram when cpustop='1', not used in this implementation
signal uaddr : std_logic_vector(23 downto 0);	
signal udata : std_logic_vector(7 downto 0);
signal uwr   : std_logic := '1';

signal mcuclk : std_logic; -- 27/2 = 13.5 M

-- hyperram mux
signal hramaddr : std_logic_vector(23 downto 0);	
signal hramdata : std_logic_vector(7 downto 0);
signal hramwr   : std_logic := '1';
signal hramrd   : std_logic := '1';

-- cmd io channel
signal req,ack  : std_logic;
signal ccdi     : std_logic_vector(7 downto 0);
signal ccdo     : std_logic_vector(7 downto 0);

signal resctr  : integer := 16000000;
signal mainres : std_logic := '1';

signal hctr : std_logic_vector(11 downto 0); -- counters from HDMI module
signal vctr : std_logic_vector( 9 downto 0); 

begin
   
process(clk,res)
begin
  if res='0' or lock135='0' or lock='0' then
    resctr <= 16000000;
  elsif rising_edge(clk) then
    if resctr/=0 then
      resctr <= resctr - 1;
    end if;
    mcuclk <= not mcuclk; -- 13 500 000
  end if;
end process;

mainres <= '1' when resctr=0 else '0';          -- act L
ramres  <= '0' when resctr>5000000 else '1';    -- act L

cgen135: Gowin_rPLL135
    port map (
        clkout => clk135,
        clkoutp => clk135p,
        lock => lock135,
        reset => not res,
        clkin => clk
    );

clkgen: Gowin_rPLL
    port map (
        clkout => clk140,
        lock => lock,
        clkoutp => clk140d,
        clkoutd => clk70,
        reset => not res,
        clkin => clk135p
    );

clkgen28: Gowin_CLKDIV -- /5
    port map (
        clkout => clk28,
        hclkin => clk140,
        resetn => res
    );

spectrum : entity work.spectrum48top 
    port map ( 
	RESETIN => not mainres, 
	CLK28IN => clk28, 
    CLK27IN => clk, 
   CLK135IN => clk135, 
     HCTRIN => hctr(10 downto 0),
     VCTRIN => vctr,
        RGB => zxrgb, 
      HSYNC => open, 
      VSYNC => open, 
 
    CPUSTOP => cpustop,
     RESVEC => resvec,
    CPUWAIT => cpuwait,
      XRAMA => xrama,
     XRAMDO => xramdo,
     XRAMDI => xramdi,
     XRAMWR => xramw,
     XRAMRD => xramr,

        REQ => req,
        ACK => ack,
       CCDO => ccdo,
       CCDI => ccdi,

     PS2CLK => PS2CLK,
     PS2DAT => PS2DAT,
      JOYIN => JOY,
     AUDIOL => zxalf,
     AUDIOR => zxarg
 );

--cpustop <= '1';

-- m1 mcu can write to the hyperram when zx cpu stopped (cpustop='0')
-- inactive feature now!
hramaddr <= xrama when cpustop='1' else uaddr;
hramdata <= xramdi when cpustop='1' else udata;
hramwr <= xramw when cpustop='1' else uwr;
hramrd <= xramr when cpustop='1' else '1';

-- hyperram controller for 8 bit cpu
hram8b: entity work.hramctrl8bit 
  port map ( 
    clk     => clk28,
    clk2x   => clk140,
    clk2xps => clk140d,
    clk1x   => clk70,
    lock    => lock,
    res     => ramres,
  
    a       => hramaddr,--x"00" & xrama,
    din     => hramdata,--xramdi,
    dout    => xramdo,
    wr      => hramwr,--xramw,
    rd      => hramrd,--xramr,
    stall   => cpuwait, -- not used, spectrum mem access ok even with the slow hram

    O_psram_ck => O_psram_ck,
    O_psram_ck_n => O_psram_ck_n,
    IO_psram_dq => IO_psram_dq,
    IO_psram_rwds => IO_psram_rwds,
    O_psram_cs_n => O_psram_cs_n,
    O_psram_reset_n => O_psram_reset_n

  );

-- M1 MPU 
cpu_m1_mpu: Gowin_EMPU_M1_Top
	port map (
		LOCKUP => open,

		UART0RXD => rxd,
		UART0TXD => txd,

		APB1PADDR => APB1PADDR,
		APB1PENABLE => APB1PENABLE,
		APB1PWRITE => APB1PWRITE,
		APB1PSTRB => APB1PSTRB,
		APB1PPROT => APB1PPROT,
		APB1PWDATA => APB1PWDATA,
		APB1PSEL => APB1PSEL,
		APB1PRDATA => APB1PRDATA,
		APB1PREADY => '1', -- no wait states, always ready
		APB1PSLVERR => '0', -- no slave error
		APB1PCLK => APB1PCLK,
		APB1PRESET => APB1PRESET,

		EXTFLASH0HRDATA => EXTFLASH0HRDATA,
		EXTFLASH0HREADYOUT => EXTFLASH0HREADYOUT,
		EXTFLASH0HRESP => EXTFLASH0HRESP,
		EXTFLASH0HTRANS => EXTFLASH0HTRANS,
		EXTFLASH0HBURST => EXTFLASH0HBURST,
		EXTFLASH0HPROT => EXTFLASH0HPROT,
		EXTFLASH0HSIZE => EXTFLASH0HSIZE,
		EXTFLASH0HWRITE => EXTFLASH0HWRITE,
		EXTFLASH0HREADYMUX => EXTFLASH0HREADYMUX,
		EXTFLASH0HMASTER => EXTFLASH0HMASTER,
		EXTFLASH0HMASTLOCK => EXTFLASH0HMASTLOCK,
		EXTFLASH0HADDR => EXTFLASH0HADDR,
		EXTFLASH0HWDATA => EXTFLASH0HWDATA,
		EXTFLASH0HSEL => EXTFLASH0HSEL,
		EXTFLASH0HCLK => EXTFLASH0HCLK,
		EXTFLASH0HRESET => EXTFLASH0HRESET,
		MOSI => sd_mosi,
		MISO => sd_miso,
		SCLK => sd_sck,
		NSS => sd_cs,
		HCLK => mcuclk, -- 13.5M 
		hwRstn => mainres
	);

-- user flash contains the M1 MPU code - fatfs driver, snapshod loader, basic dos commands
ucflash: GW_FLASH 
  port map (
    hclk                   => EXTFLASH0HCLK,
    hresetn                => EXTFLASH0HRESET,
    targflash0_hsel_i      => EXTFLASH0HSEL,
    targflash0_haddr_i     => EXTFLASH0HADDR, 
    targflash0_htrans_i    => EXTFLASH0HTRANS,
    targflash0_hwrite_i    => EXTFLASH0HWRITE,
    targflash0_hsize_i     => EXTFLASH0HSIZE,
    targflash0_hburst_i    => EXTFLASH0HBURST,
    targflash0_hprot_i     => EXTFLASH0HPROT,
    targflash0_memattr_i   => "00",
    targflash0_exreq_i     => '0',
    targflash0_hmaster_i   => EXTFLASH0HMASTER,
    targflash0_hwdata_i    => EXTFLASH0HWDATA,
    targflash0_hmastlock_i => EXTFLASH0HMASTLOCK,
    targflash0_hreadymux_i => EXTFLASH0HREADYMUX,
    targflash0_hauser_i    => '0',
    targflash0_hwuser_i    => "0000",
    targflash0_hrdata_o    => EXTFLASH0HRDATA,
    targflash0_hreadyout_o => EXTFLASH0HREADYOUT,
    targflash0_hresp_o     => EXTFLASH0HRESP(0),
    targflash0_exresp_o    => open,
    targflash0_hruser_o    => open,
    flash_err_o            => open,
    flash_int_o            => open,
    pclk                   => EXTFLASH0HCLK,
    pclkg                  => EXTFLASH0HCLK
);


process(APB1PCLK,APB1PENABLE,APB1PWRITE)
begin
  if rising_edge(APB1PCLK) then 
    ack <= '0';
    if APB1PENABLE='1' and APB1PWRITE='1' then     
        case APB1PADDR(3 downto 2) is
--        when "00"=> -- #define UDA         (*((volatile unsigned long *) 0x60000000))   
--          udata <= APB1PWDATA(7 downto 0);
--          uaddr <= APB1PWDATA(31 downto 8); -- 16M address space
--        when "01"=> -- #define UDCW        (*((volatile unsigned long *) 0x60000004))   
--         cpustop <= APB1PWDATA(0); -- act L
--             uwr <= APB1PWDATA(1); -- act L
--           zxres <= APB1PWDATA(2); -- act L
--          ramres <= APB1PWDATA(3); -- act L
        when "10"=> -- #define CCDI        (*((volatile unsigned long *) 0x60000008))   
            ccdi <= APB1PWDATA(7 downto 0);
             ack <= '1';
        when others=> null;
        end case;
    end if;
  end if;
end process;

led <= '1' & (not (ramres & zxres & uwr & cpustop));
APB1PRDATA(7 downto 0) <= ccdo;
APB1PRDATA(8) <= cpuwait;
APB1PRDATA(9) <= lock;
APB1PRDATA(10)<= req;

  process(clk)
  begin
    if rising_edge(clk)  then
      if aclkctr>=421 then --27000000/32000/2 then
        aclkctr <=0;
        clkAudio <= not clkAudio;
      else
        aclkctr <= aclkctr + 1;
      end if;
    end if;
  end process;

 hdmiout : hdmi
	port map (
        clk_pixel_x5 => clk135,
        clk_pixel    => clk,
        clk_audio    => clkAudio,
        reset        => not mainres,
        rgb          => zxrgb,
        audio_l      => zxalf,
        audio_r      => zxarg,
        tmds_d_n     => tmds_d_n,
        tmds_d_p     => tmds_d_p,
        tmds_clk_n   => tmds_clk_n,
        tmds_clk_p   => tmds_clk_p,
        cx           => hctr,
        cy           => vctr,
        frame_width  => open,
        frame_height => open,
        screen_width => open,
        screen_height=> open
	);

end Behavioral;