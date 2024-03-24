--Copyright (C)2014-2022 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: Template file for instantiation
--GOWIN Version: V1.9.8.08
--Part Number: GW1NR-LV9QN88PC6/I5
--Device: GW1NR-9C
--Created Time: Sun Mar 24 14:02:12 2024

--Change the instance name and port connections to the signal names
----------Copy here to design--------

component Gowin_rPLL135
    port (
        clkout: out std_logic;
        lock: out std_logic;
        clkoutp: out std_logic;
        reset: in std_logic;
        clkin: in std_logic
    );
end component;

your_instance_name: Gowin_rPLL135
    port map (
        clkout => clkout_o,
        lock => lock_o,
        clkoutp => clkoutp_o,
        reset => reset_i,
        clkin => clkin_i
    );

----------Copy end-------------------
