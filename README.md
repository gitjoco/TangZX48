<b>ZX Spectrum 48K implementation on Tang Nano 9K</b>

FPGA project contains the ZX spectrum implementation with PS/2 keyboard and HDMI video/audio output.
MPU has an M1 cpu which handles the FATFS file system and basic DOS commands. 

Check out the .CST file for the pinouts. Use a PS/2 kebvoard which works with 3.3V

<pre>IO_LOC "joy[4]" 57;
IO_LOC "joy[3]" 56;
IO_LOC "joy[2]" 55;
IO_LOC "joy[1]" 54;
IO_LOC "joy[0]" 53;

IO_LOC "ps2dat" 32;
IO_LOC "ps2clk" 31;</pre>

In the Spectrum's command set, the original COPY command was replaced by CMD, where you can type basic 
DOS commands, like:

<pre>dir
ver
vol
pwd
cd
inf
</pre>

It can load .sna and .z80 files. Put your games to an SD card (formatted to FAT32) and place the files
there. To load a game, type:
<pre>
CMD sna jetpac
CMD sna willy
</pre>

The Gowin G1NR-9C fpga has built in hyperram, that is used for the upper ram of the ZX Spectrum. <br />
Hyperram driver original source:
<a href="https://mjoergen.github.io/HyperRAM/">https://mjoergen.github.io/HyperRAM/</a> <br />
<a href="https://github.com/MJoergen/HyperRAM/issues">https://github.com/MJoergen/HyperRAM/issues</a>
<br />
<br />
HDMI source: By Sameer Puri <a href="https://github.com/sameer">https://github.com/sameer</a>
<br />
<br />
Thanks for those great projects!

The ULA version in this project is generating HDMI compatible signals, where the main clock frequency is
27MHz, using the standard video mode 720x576p. 








