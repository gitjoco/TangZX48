ZX Spectrum 48K implementation on baord Tang Nano 9K

FPGA project contains the ZX spectrum implementation with PS/2 keyboard and HDMI video/audio output.
MPU has an M1 cpu which handles the FATFS file system and basic DOS commands. 

Check out the .CST file for the pinouts. Use PS/2 keyvoard that works with 3.3V

IO_LOC "joy[4]" 57;
IO_LOC "joy[3]" 56;
IO_LOC "joy[2]" 55;
IO_LOC "joy[1]" 54;
IO_LOC "joy[0]" 53;

IO_LOC "ps2dat" 32;
IO_LOC "ps2clk" 31;

In the Spectrum's command set, the original COPY command was replaced by CMD, where you can type basic 
DOS commands, like:

dir
ver
vol

Project can load .sna and .z80 files. Put your games to an SD card (formatted to FAT32) and place the files
there. To load a game, type:

CMD sna jetpac
CMD sna willy






