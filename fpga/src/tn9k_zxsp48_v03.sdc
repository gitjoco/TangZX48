//Copyright (C)2014-2023 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.09 
//Created Time: 2023-05-14 07:27:55
create_clock -name clk135 -period 7.407 -waveform {0 3.704} [get_nets {clk135}] -add
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}] -add
