//
// Copyright (c) 2016-2024 Jozsef Laszlo (rbendr@gmail.com)
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../../FAT/ff.h"
#include "snaps.h"
/*************************************************************************/

byte pcl, pch;
int  sp;
int ll;

FILE* fo;

char* isSna(char* str)
{
	char *c;
	ll=strlen(str);
	if (ll>4)
	{
		c=str+ll-4;
		if (!strcmp(c,".sna")) return c;
		if (!strcmp(c,".SNA")) return c;
	}
	return NULL;
}


char* isZ80Sna(char* str)
{
	char *c;
	ll=strlen(str);
	if (ll>4)
	{
		c=str+ll-4;
		if (!strcmp(c,".z80")) return c;
		if (!strcmp(c,".Z80")) return c;
	}
	return NULL;
}
void SendByte(byte);

void ZByteSend(int a, byte b)
{
	if (a == sp + 1) b = pch;
	if (a == sp) b = pcl;	
	//fwrite(&b, 1, 1, fo);
	SendByte(b);
}

int z80_v1(FIL* f, int addr)
{
	UINT br;
	int  p = 0, n = 0;
	int  t;
	byte b[256], xx, yy;

	printf("z80_v1 A=%04x\r\n",addr);

	while (1)
	{
		//fread(b + n, 1, 256 - n, f);
		f_read(f,b + n, 256 - n, &br);
		do
		{
			if (b[p] == 0x00 && b[p + 1] == 0xed && b[p + 2] == 0xed && b[p + 3] == 0x00)
				return addr;
			else if (b[p] == 0xed && b[p + 1] == 0xed)
			{
				p += 2;
				xx = b[p++]; yy = b[p++];
				for (int i = 0; i < xx; i++) ZByteSend(addr++, yy);				
			}
			else
				ZByteSend(addr++, b[p++]);

		} while (p < 252);

		n = 256 - p;
		for (int i = p; i < 256; i++) b[i - p] = b[i];
		p = 0;
	}
	return addr;
}

int z80_v2v3(FIL* f, int addr, int bLen)
{
	UINT br;
	int  p = 0;
	int  oLen = bLen;
	int  q = 0;
	byte b[256], xx, yy;

	printf("z80_v2v3 A=%04x L=%d\r\n",addr,bLen);

	// if block is not compressed it will be 16384 bytes long
	if (bLen == 16384)
	{
		for (int i = 0; i < 64; i++) // 64*256 = 16384
		{
			//fread(b, 1, 256, f);
			f_read(f,b,256,&br);
			for (int j = 0; j < 256; j++) ZByteSend(addr++, b[j]);
		}
		return addr;
	}

	//bLen = bLen - fread(b, 1, bLen < 256 ? bLen : 256, f);
	f_read(f,b,bLen < 256 ? bLen : 256,&br);
	bLen = bLen - br;

	while (q < oLen)
	{
		if (b[p] == 0xed && b[p + 1] == 0xed)
		{
			p += 2; q += 4;
			xx = b[p++]; yy = b[p++];
			for (int i = 0; i < xx; i++) ZByteSend(addr++, yy);			
		}
		else
		{
			ZByteSend(addr++, b[p++]); q++;
		}
		if (p >= 252)
		{ // p reaches end of chunk buffer
			for (int i = p; i < 256; i++) b[i - p] = b[i];
			//bLen = bLen - fread(b + 256 - p, 1, bLen < p ? bLen : p, f);
			f_read(f, b + 256 - p, bLen < p ? bLen : p, &br);
			bLen = bLen - br;
			p = 0;
		}
	}
	return addr;
}

int IsZ80Snap48K(const char* filename)
{
	Z80header h;
	UINT br;
	FIL f;
	int is48 = 0;
	byte b[64];

	if ( f_open(&f,filename, FA_OPEN_EXISTING | FA_READ) == FR_OK)
	{
		f_read(&f, &h, sizeof(h), &br); // V1 header
		if (h.PCH == 0 && h.PCL == 0)
		{
			// v2.01 or v3.0
			//fread(b, 1, 2, f); // additional header length
			f_read(&f,b,2,&br);
			if (b[0] == 23)
			{
				//fread(b, 1, 23, f);
				f_read(&f,b,23,&br);
				is48 = (b[2] < 2);
				printf("Z80 file V2\r\n");
			}
			else
			{
				//fread(b, 1, b[0] == 54 ? 54 : 55, f); // b[0]==54 || b[0]==55
				f_read(&f,b,b[0] == 54 ? 54 : 55,&br);
				is48 = (b[2] < 2 || b[2] == 3);
				printf("Z80 file V3\r\n");
			}
		}
		else
		{
			is48 = 1;
			printf("Z80 file V1\r\n");
		}
		f_close(&f);
	}
	return is48;
}

int LoadZ80asSNA(FIL* f)
{
	int rv = 0;
	UINT br;
	SNAheader sh;
	Z80header h;
	char v = 1;
	char compr = 0;
	char is48 = 0;
	int  n;
	int  sn = 0;
	byte b[256];
	int seg4000 = 0, seg8000 = 0, segc000 = 0;
	int len4000 = 1, len8000 = 1, lenc000 = 1;

	//if (FR_OK == f_open(&f,filename, FA_OPEN_EXISTING | FA_READ))
	{
		//fread(&h, sizeof(h), 1, f);
		f_read(f,&h, sizeof(h), &br);
		if (h.flags == 255) h.flags = 1;
		// convert header
		sh.A = h.A; sh.A2 = h.A2;
		sh.F = h.F; sh.F2 = h.F2;
		sh.B = h.B; sh.C = h.C; sh.B2 = h.B2; sh.C2 = h.C2;
		sh.D = h.D; sh.E = h.E; sh.D2 = h.D2; sh.E2 = h.E2;
		sh.H = h.H; sh.L = h.L; sh.H2 = h.H2; sh.L2 = h.L2;
		//sh.SPH = h.SPH; sh.SPL = h.SPL;
		sh.XH = h.XH; sh.XL = h.XL;
		sh.YH = h.YH; sh.YL = h.YL;
		sh.I = h.I; sh.R = h.R | (h.flags & 1 ? 128 : 0);
		sh.Interrupt = (h.DIEI ? 0xff : 0); // TODO check !
		sh.IntMode = h.flags2 & 3;
		sh.BorderColor = (h.flags >> 1) & 7;
		pcl = h.PCL;
		pch = h.PCH;
		sp = h.SPL + (h.SPH << 8);
		sp = sp - 2; // we will push pc for sna
		sh.SPH = (sp >> 8) & 0xff;
		sh.SPL = sp & 0xff;

		if (h.PCH == 0 && h.PCL == 0)
		{
			// v2.01 or v3.0
			f_read(f,b, 2, &br); // additional header length
			if (b[0] == 23)
			{
				v = 2;
				f_read(f,b, 23, &br);
				is48 = (b[2] < 2);
				printf("Z80 file V2 %d\r\n", b[2]);
			}
			else
			{
				v = 3;
				//fread(b, 1, b[0], f); // b[0]==54 || b[0]==55
				f_read(f,b, b[0], &br);
				is48 = (b[2] < 2 || b[2] == 3);
				printf("Z80 file V3 %d\r\n", b[2]);
			}
			h.PCL = b[0];
			h.PCH = b[1];
			pcl = b[0];
			pch = b[1];
			// V2/V3 read data blocks
			printf("SP:%04x PC:%04x\r\n", sp, pcl + (pch << 8));

			if (!is48) return 0; // do not load snapshot for 128k machines

			// send header
			byte* snah = (byte*)(&sh);
			for (int i = 0; i < 27; i++) //fwrite(snah++, 1, 1, fo);
			 SendByte(*snah++);

		    // find blocks
			while (sn != 3)
			{
				//n = fread(b, 1, 3, f); // lenL lenH blktyp
				f_read(f,b,3,&br);

				if (br != 3) break;
				n = b[0] + 256 * b[1];
				if (n == 0xffff) n = 16384;
				switch (b[2])
				{
				case 4: //8000-bfff
					seg8000 = f_tell(f);
					//fseek(f, n, SEEK_CUR);
					f_lseek(f,seg8000+n);
					len8000 = n;
					sn++;
					printf("found seg8000 %04x %d\r\n",seg8000,len8000);
					break;
				case 5: //c000-ffff
					segc000 = f_tell(f);
					//fseek(f, n, SEEK_CUR);
					f_lseek(f,segc000+n);
					lenc000 = n;
					printf("found segc000 %04x %d\r\n",segc000,lenc000);
					sn++;
					break;
				case 8: //4000-7fff
					seg4000 = f_tell(f);
					//fseek(f, n, SEEK_CUR);
					f_lseek(f,seg4000+n);
					len4000 = n;
					printf("found seg4000 %04x %d\r\n",seg4000,len4000);
					sn++;
					break;
				}
			}

			f_lseek(f, seg4000);
			z80_v2v3(f, 16384, len4000);
			f_lseek(f, seg8000);
			z80_v2v3(f, 32768, len8000);
			f_lseek(f, segc000);
			z80_v2v3(f, 49152, lenc000);
		}
		else
		{
			printf("SP:%04x PC:%04x\r\n", sp, pcl + (pch << 8));

			// send header
			byte* snah = (byte*)(&sh);
			for (int i = 0; i < 27; i++) //fwrite(snah++, 1, 1, fo);
			   SendByte(*snah++);

			printf("Z80 file V1\r\n");
			// V1 read data, compressed data
			compr = ((h.flags & 0x20) == 0x20);
			if (compr) z80_v1(f, 16384);
			else
			{
				int addr = 16384;
				// read uncompressed block
				while (!f_eof(f))
				{
					//n = fread(b, 1, 128, f);
					f_read(f,b,128,&br);
					n=br;
					for (int i = 0; i < n; i++) ZByteSend(addr++, b[i]);					
				}
			}
		}

		//f_close(&f);
	}
	return rv;
}
