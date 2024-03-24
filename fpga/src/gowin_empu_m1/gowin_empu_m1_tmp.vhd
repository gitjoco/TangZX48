--Copyright (C)2014-2022 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--GOWIN Version: GowinSynthesis V1.9.8.09
--Part Number: GW1NR-LV9QN88PC6/I5
--Device: GW1NR-9C
--Created Time: Sun May 14 16:07:10 2023

--Change the instance name and port connections to the signal names
----------Copy here to design--------

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

your_instance_name: Gowin_EMPU_M1_Top
	port map (
		LOCKUP => LOCKUP_o,
		UART0RXD => UART0RXD_i,
		UART0TXD => UART0TXD_o,
		APB1PADDR => APB1PADDR_o,
		APB1PENABLE => APB1PENABLE_o,
		APB1PWRITE => APB1PWRITE_o,
		APB1PSTRB => APB1PSTRB_o,
		APB1PPROT => APB1PPROT_o,
		APB1PWDATA => APB1PWDATA_o,
		APB1PSEL => APB1PSEL_o,
		APB1PRDATA => APB1PRDATA_i,
		APB1PREADY => APB1PREADY_i,
		APB1PSLVERR => APB1PSLVERR_i,
		APB1PCLK => APB1PCLK_o,
		APB1PRESET => APB1PRESET_o,
		EXTFLASH0HRDATA => EXTFLASH0HRDATA_i,
		EXTFLASH0HREADYOUT => EXTFLASH0HREADYOUT_i,
		EXTFLASH0HRESP => EXTFLASH0HRESP_i,
		EXTFLASH0HTRANS => EXTFLASH0HTRANS_o,
		EXTFLASH0HBURST => EXTFLASH0HBURST_o,
		EXTFLASH0HPROT => EXTFLASH0HPROT_o,
		EXTFLASH0HSIZE => EXTFLASH0HSIZE_o,
		EXTFLASH0HWRITE => EXTFLASH0HWRITE_o,
		EXTFLASH0HREADYMUX => EXTFLASH0HREADYMUX_o,
		EXTFLASH0HMASTER => EXTFLASH0HMASTER_o,
		EXTFLASH0HMASTLOCK => EXTFLASH0HMASTLOCK_o,
		EXTFLASH0HADDR => EXTFLASH0HADDR_o,
		EXTFLASH0HWDATA => EXTFLASH0HWDATA_o,
		EXTFLASH0HSEL => EXTFLASH0HSEL_o,
		EXTFLASH0HCLK => EXTFLASH0HCLK_o,
		EXTFLASH0HRESET => EXTFLASH0HRESET_o,
		MOSI => MOSI_o,
		MISO => MISO_i,
		SCLK => SCLK_o,
		NSS => NSS_o,
		HCLK => HCLK_i,
		hwRstn => hwRstn_i
	);

----------Copy end-------------------
