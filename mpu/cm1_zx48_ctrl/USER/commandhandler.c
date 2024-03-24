/*
 * commandhandler.c
 *
 *  Created on: Feb 25, 2022
 *      Author: joco

  Copyright (c) 2016-2024 Jozsef Laszlo (rbendr@gmail.com)


 */
#include <stdio.h>
#include <ctype.h>
#include "commandhandler.h"
#include "snaps.h"

void PrtHex(uint8_t h)
{
	char s[5];
	sprintf(s,"%02x",h);
	prt(s);
}

void PrtHexW(uint16_t h)
{
	char s[5];
	sprintf(s,"%04x",h);
	prt(s);
}
void PrtInt(int i)
{
	char s[8];
	sprintf(s,"%d",i);
	prt(s);
}

uint8_t CommandPending()
{
	uint32_t r = UDA;
	return (r & 0x0400) == 0x0400; // check REQ
}

int SendRecv(int b)
{
	int r;
	while ( ((r = UDA)&0x0400)==0x0000 ); // wait for REQ
    // send byte
	CCDI = b;
	return r&0xff;
}


FATFS FatFs;	// FatFs work area needed for each volume
FIL   File;		// File object needed for each open file
DIR   dir;
char  card_mounted = 0;
char  fileOpen = 0;
char  dirOpen = 0;
char  nl[3] = { 0x0d,0x00,0x00 };

void SendByte(byte b)
{
	SendRecv(b);
}

byte RecvByte()
{
	byte r = SendRecv(0xff);
	return r;
}

// receive a null terminated string
void GetString(char *dst, int maxLen)
{
	byte b;
	int  i = 0;
	do
	{
		b = RecvByte();
		dst[i++] = tolower((char)b);
	} while (b && i < maxLen);
	if (b) dst[i] = '\0'; // closing zero if maxLen reached
}

void SendWord(int d)
{
	SendByte(d & 0xff);
	SendByte((d >> 8) & 0xff);
}

void SendDWORD(DWORD d)
{
	SendByte(d & 0xff);
	SendByte((d >> 8) & 0xff);
	SendByte((d >> 16) & 0xff);
	SendByte((d >> 24) & 0xff);
}

char SendStrL(char* str, int len)
{
	byte b;
	char *c = str;
	while (*c && len)
	{
		b = SendRecv(*c++); len--;
		if (b==CMD_CANCEL) return 0x01; // must stop
	}
	return 0x00;
}

char SendStr(char* str)
{
	byte b;
	char *c = str;
	while (*c)
	{
		b = SendRecv(*c++);
		if (b==CMD_CANCEL) return 0x01; // must stop
	}
	return 0x00;
}

void locase(char* str)
{
	char *c = str;
	while (*c)
	{
		if (*c>='A' && *c<='Z') *c|=0x20;
		c++;
	}
}

void upcase(char* str)
{
	char *c = str;
	while (*c)
	{
		if (*c>='a' && *c<='z') *c-=0x20;
		c++;
	}
}

int snapZ80=0;

byte cmd_cd()
{
	char dirName[128];
	GetString(dirName, 120);
	//prt("cd ");prt(dirName);
	if (f_chdir(dirName) == FR_OK)
	{
		//prt(" ok\r\n");
		return RESP_OK;
	}
	//prt("failed\r\n");
	return RESP_ERROR;
}

byte cmd_opendir()
{
	char dirName[128];
	GetString(dirName, 120);

	f_closedir(&dir);
	dirOpen = 0;

	if (f_opendir(&dir, dirName) == FR_OK)
	{
		//prt("opendir ok\r\n");
		dirOpen = 1;
		return RESP_OK;
	}
	//prt("opendir failed\r\n");
	return RESP_ERROR;
}

byte cmd_closedir()
{
	//prt("closedir\r\n");
	f_closedir(&dir);
	dirOpen = 0;
	return RESP_OK;
}

byte cmd_readdir()
{
	char t[64];
	static FILINFO fno;
	FRESULT res;
	DWORD fsize;
	if (!dirOpen) return RESP_ERROR;
	res = f_readdir(&dir, &fno);
	if (res != FR_OK || fno.fname[0] == 0)
	{
		prt("Dir END\r\n");
		//PrtInt(dirNumEntries); USARTSend("\r\n");
		return RESP_EOS;
	}
	strncpy(t,fno.fname,61);
	locase(t);      // filenames lowercase
	fsize = (DWORD)fno.fsize;
	if (fno.fattrib & AM_DIR) fsize|=0x80000000; // fsize MSB is high if directory
	//prt("readdir "); prt(t); prt(" ");PrtHexW(fsize); prt("\r\n");
	SendByte(RESP_OK);
	//prt("#1");
    SendDWORD(fsize);
    //prt("#2");
	SendStrL(t,strlen(t));
	//prt("#3");
	return 0x00; // end of string
}

byte cmd_fopen()
{
	int i;
	char hasFile=0;
	char fname[64];
	char fnorg[64];
	DWORD fsize;

	GetString(fname, 31);
	strcpy(fnorg,fname);
    prt("fopen ");prt(fname);prt("\r\n");

	if (fileOpen == 0)
	{
		if (f_open(&(File), fname, FA_OPEN_EXISTING | FA_READ) == FR_OK) hasFile=1;

		if (hasFile==0)
		{
			strcat(fname,".sna");
			if (f_open(&(File), fname, FA_OPEN_EXISTING | FA_READ) == FR_OK) hasFile=1;
		}

		if (hasFile==0)
		{
			strcpy(fname,fnorg);
			strcat(fname,".z80");
			if (f_open(&(File), fname, FA_OPEN_EXISTING | FA_READ) == FR_OK) hasFile=1;
		}

		if (isZ80Sna(fname))
		{
		   		snapZ80 = IsZ80Snap48K(fname);
		   		if (snapZ80==0)
		   		{
		   			printf("Incompatible Z80 snap found.\r\n");
		   			return RESP_Z80ERR;
		   		}
		}

		if (hasFile)
		{
			fsize = f_size(&(File)); //USARTSend("FileId ");PrtHex(i);
			fileOpen = 1; // opened for read
			SendByte(RESP_OK);

			if (snapZ80)
			{
				fsize=49179; // faking
				printf("Z80 snap faking as if it was SNA file.\r\n");
			}

			SendWord(fsize); //PrtHexW(fsize>>16);PrtHexW(fsize&0xffff);
			prt("OK ");
			prt(" length=");
			PrtInt(fsize);
			prt("\r\n");
			return RESP_OK; // ok
		}
	}
	prt("ERR\r\n");
	return RESP_ERROR;
}

byte cmd_fcreate()
{
	int i;
	//byte b;
	char fname[32];
	GetString(fname, 31);
	prt("fcrate ");prt(fname);prt("\r\n");

	if (fileOpen == 0)
	{
		if (f_open(&(File), fname, FA_CREATE_ALWAYS | FA_WRITE) == FR_OK)
		{
			fileOpen = 2; // opened for write
			prt("OK \n");
			return RESP_OK; // ok
		}
	}

		prt("ERR\r\n");
	return RESP_ERROR;
}

byte cmd_fclose()
{
	prt("fclose \n");
	if (fileOpen != 0)
	{
		f_close(&(File));
		fileOpen = 0;
	}
	return RESP_OK;
}

byte cmd_read()
{
	uint16_t l,h;
	UINT br,t;
	int i,n,j;
	byte buff[64];

	l = RecvByte();
	h = RecvByte();
	n = (h<<8)|l;

	if (snapZ80)
	{
		prt("cmd_rdblock reads Z80 snapshot\r\n");
		LoadZ80asSNA( &(File) );
		prt("Reading Z80 snapshot done\r\n");
		snapZ80=0;
		return RESP_OK;
	}

	prt("cmd_read "); PrtHexW(n); prt("\r\n");
    j=0;
	do
	{
	   t = n<64 ? n : 64;
	   f_read(&(File), &buff, t , &br);
	   for(i=0;i<t;i++) { SendByte(buff[i]); j++; }
	   n = n - 64;
	} while (n>0);
	prt("Sent: "); PrtHexW(j); prt(" bytes\r\n");
	return RESP_OK;
}


byte cmd_write()
{
	uint16_t l,h;
	UINT br,t;
	int i,n,j;
	byte buff[64];

	l = RecvByte();
	h = RecvByte();
	n = (h<<8)|l;

	prt("cmd_write "); PrtHexW(n); prt("\r\n");
    j=0;
	if (fileOpen == 2) // open for write
	{
		do
		{
		   t = n<64 ? n : 64;
		   for(i=0;i<t;i++) { buff[i]=RecvByte(); j++; }
		   f_write(&(File), &buff, t , &br);
		   n = n - 64;
		} while (n>0);
		prt("Written: "); PrtHexW(j); prt(" bytes\r\n");
		return RESP_OK;
	}
	return RESP_ERROR;
}

byte cmd_echo()
{
	//prt("S_ECHO\n\r");
	byte b = RecvByte();
	prt("ECHO");
	PrtHex(b);
	PrtHex(b^0xff);
	prt("\n");
	return b ^ 0xff;
}

char* NextWord(char *cmdline, char** nxt)
{
	if (!cmdline) return NULL;
	char *rv;
	char* c = cmdline;
	while (*c == ' ') c++;
	rv = c;

	if (*c=='"')
	{
		c++; rv = c;
		while (*c != '"' && *c != '\0') c++;
		*nxt = *c ? c + 2 : NULL;
		*c = '\0';
		return rv;
	}

	while (*c != ' ' && *c != '\0') c++;
	*nxt = *c ? c + 1 : NULL;
	*c = '\0';
	return rv;
}

byte tcmd_pwd(char *p)
{
	char pwd[128];
	if (f_getcwd(pwd, 127) == FR_OK)
	{
		SendStr(pwd);
		SendStr(nl);
		return RESP_OK;
	}
	return RESP_ERROR;
}

byte tcmd_ver(char *p)
{
	char s[32];
	strncpy(s,__DATE__,11); s[11]=0;
	upcase(s);
	SendStr("SDDRV V1.2 ");
	SendStrL(s,11);
	SendStr(" ");
	SendStrL(__TIME__,8);
	SendStr(nl);
	return RESP_OK;
}

byte tcmd_info(char *p)
{
	//       01234567890123456789012345678901
	SendStr("JOZSEF LASZLO, RBENDR@GMAIL.COM"); SendStr(nl);
	SendStr("2019-2024 ALL RIGHTS RESERVED"); SendStr(nl);
	SendStr("-HANG ON! THE GAME IS NOT OVER-"); SendStr(nl);

	return RESP_OK;
}

FIL tmpfil;

byte tcmd_cat(char *p)
{
	char buff[256];
	char *d = p;
	char *p1 = NextWord(d, &d);

	if (p1 && f_open(&tmpfil, p1, FA_OPEN_EXISTING | FA_READ) == FR_OK)
	{
		while (!f_eof(&tmpfil))
		{
			f_gets(buff,250,&tmpfil);
			if (SendStr(buff)) break; // stop if sendstr received CMD_CANCEL
			SendStr(nl);
		}
		f_close(&tmpfil);
		return RESP_OK;
	}
	return RESP_ERROR;
}

void zpadstr(char *s, int n)
{
	char t[16];
	if (strlen(s)>=n) return;
	strcpy(t,"000000");
	strcat(t,s);
	strcpy(s,t+strlen(t)-n);
}

byte tcmd_dump(char *p)
{
	byte buff[8];
	byte b,brk;
	char *d = p;
	char *p1 = NextWord(d, &d);
	char *p2 = NextWord(d, &d);
	char s[32],t[9];
	UINT br;
	UINT a;
	int  i,ln,offs=0;

	if (p2) offs = atoi(p2);


	if (p1 && f_open(&tmpfil, p1, FA_OPEN_EXISTING | FA_READ) == FR_OK)
	{
		a = offs;

		if (offs!=0) f_lseek(&tmpfil,offs);

		while (!f_eof(&tmpfil))
		{
			f_read(&tmpfil, buff, 8, &br);
			itoa(a,s,16); zpadstr(s,4);
			strcat(s," ");
			if (SendStr(s)) break;

			for (i = 0; i < br; i++)
			{
				itoa(buff[i],s,16);
				zpadstr(s,2);
				strcat(s," ");
				t[i]= buff[i]<128 && buff[i]>31 ? buff[i] : '.';

				brk = SendStr(s);
				if (brk) break;
			}
			t[i]=0;
			brk = SendStr(t);
			if (brk) break;

			if (brk) break;
			a += br;
			if (SendStr(nl)) break;
		}
		f_close(&tmpfil);
		return RESP_OK;
	}

	return RESP_ERROR;
}

byte tcmd_vol(char *p)
{
	char rv[128];
	char label[16];
	FATFS* fs = &FatFs;
	DWORD vsn, nclst;
	FRESULT fr = f_getlabel("", label, &vsn);
	if (fr == FR_OK)
	{
		fr = f_getfree("", &nclst, &fs);
		if (fr == FR_OK)
		{
			DWORD tot_mb = ((fs->n_fatent - 2) * fs->csize) >> 11;
			DWORD fre_mb = (nclst * fs->csize) >> 11;
			//sprintf(rv, "%s Total:%lu Free: %lu\n", label, tot_kb, fre_kb);
			strcpy(rv,"VOL: ");
			if (strlen(label)==0)
				strcat(rv,"--");
			else
				strcat(rv,label);
			strcat(rv,"\rTOTAL: ");
			itoa(tot_mb,label,10); strcat(rv,label);
			strcat(rv," MB, FREE: ");
			itoa(fre_mb,label,10); strcat(rv,label);
			strcat(rv," MB");
			SendStr(rv);
			return RESP_OK;
		}
	}
	else {
		SendStr("No card present or FAT/FS error");
	}
	return RESP_ERROR;
}

void upstr(char *s)
{
	char *c=s;
	while (*c)
	{
		*c=toupper(*c);
		c++;
	}
}

byte tcmd_dir(char *p)
{
	int n = 0, sz, i;
	int fcnt=0;
	int dcnt=0;
	byte brk=0;
	FRESULT res;
	DIR dir;
	static FILINFO fno;
	char s[128],t[16];
	char pwd[128];
	f_getcwd(pwd, 127);


	char *d = p;
	char *p1 = NextWord(d, &d);
	char sort = p1 && *p1 == 's';


	res = f_opendir(&dir, pwd);                       // Open the directory
	if (res == FR_OK) {
		for (;;) {
			res = f_readdir(&dir, &fno);                   // Read a directory item
			upstr(fno.fname);
			if (res != FR_OK || fno.fname[0] == 0) break;  // Break on error or end of dir
			/*if (fno.fattrib & AM_DIR)
			{
                SendStr("[DIR] ");
                SendStr(fno.fname);
			}
			else
			{
				SendStr(fno.fname);
				SendStr("   ");
            	itoa((int)fno.fsize,t,10);
            	SendStr(t);
			}
			SendStr(nl);*/
			if (fno.fattrib & AM_DIR) {                    // It is a directory
				sprintf(s, "%12s <DIR>", fno.fname);
			}
			else {                                       // It is a file.
				sprintf(s, "%12s %lu", fno.fname, fno.fsize);
			}
			brk = SendStr(s);
			if (brk) break;
			SendStr(nl);

		}
	}
	f_closedir(&dir);


	return RESP_OK;
}

byte Copy(char* src, char* dst)
{
	byte buff[512];
	UINT r, w;
	// internal implementation of copy
	FIL fsrc;
	FIL fdst;
	if (f_open(&fsrc, src, FA_OPEN_EXISTING | FA_READ) == FR_OK && f_open(&fdst, dst, FA_CREATE_ALWAYS | FA_WRITE) == FR_OK)
	{
		do
		{
			f_read(&fsrc, buff, 512, &r);
			f_write(&fdst, buff, r, &w);
		} while (r == 512);
		f_close(&fdst);
		f_close(&fsrc);
		return RESP_OK;
	}
	return RESP_ERROR;
}

byte tcmd_copy(char *p)
{
	char *d = p;
	char *p1 = NextWord(d, &d);
	char *p2 = NextWord(d, &d);

	if (p1 && p2)
	{
		return Copy(p1, p2);
	}
	SendStr("COPY ERROR");
	return RESP_ERROR;
}

byte tcmd_cd(char *p)
{
	char *d = p;
	char *p1 = NextWord(d, &d);

	if (p1)
	{
		if (f_chdir(p1) == FR_OK) return tcmd_pwd(NULL);
	}
	else
	{
		if (f_chdir("/") == FR_OK) return tcmd_pwd(NULL);
	}
	SendStr("CD ERROR");
	return RESP_ERROR;
}

byte tcmd_mkdir(char *p)
{
	char *d = p;
	char *p1 = NextWord(d, &d);
	char s[32];
	FRESULT res;
	if (p1)
	{
		res = f_mkdir(p1);
		if (res)
		{
			//sprintf(s, "ERROR: %02x [%s]", res, p1);
			SendStr("MKDIR ERROR");
			SendStr(nl);
		}
		return RESP_OK;
	}
	return RESP_ERROR;
}

byte tcmd_del(char *p)
{
	char *d = p;
	char *p1 = NextWord(d, &d);
	char s[32];
	FRESULT res;

	if (p1)
	{
		res = f_unlink(p1);
		if (res)
		{
			//sprintf(s, "ERROR: %02x [%s]", res, p1);
			SendStr("DELETE ERROR");
			SendStr(nl);
		}
		return RESP_OK;
	}
	return RESP_ERROR;
}

byte tcmd_rename(char *p)
{
	char *d = p;
	char *p1 = NextWord(d, &d);
	char *p2 = NextWord(d, &d);
	if (f_rename(p1, p2) == FR_OK) return RESP_OK;
	SendStr("RENAME ERROR");
	return RESP_ERROR;
}

const funcPtr2 tcmds[] = {
	tcmd_pwd,tcmd_ver,tcmd_info,tcmd_cat,tcmd_dump,tcmd_vol,tcmd_dir,tcmd_copy,
	tcmd_cd,tcmd_mkdir,tcmd_del
};
/*
	Parameter: text-command closed by zero
	Response: 0x02 text closed by zero
	0x01 if error
	“0x04-cancel” can be sent to terminate text transfer
*/
const char tcmd[] = "@pwdAverBinfoCcatDdumpEvolFdirGcopyHcdImkdirJdel";

byte cmd_text()
{
	int  i;
	char *p;
	char cmdLine[128];
	GetString(cmdLine, 127);
	if (strlen(cmdLine)==0) strcpy(cmdLine,"dir");
	char *cmd = NextWord(cmdLine, &p);
	char *d = strstr(tcmd, cmd);
	if (d)
	{
		i = *(d - 1) - '@';
		SendByte(RESP_TEXT);
		byte r = tcmds[i](p);
		SendByte(0x00); // end of string
		return r;
	}
	return RESP_ERROR;
}


funcPtr cmds[] = {
	cmd_fopen,cmd_fcreate,cmd_fclose,cmd_read,cmd_write,
	cmd_text,cmd_echo,cmd_cd,cmd_opendir,cmd_closedir,cmd_readdir
};

void HandleCommand()
{
	uint8_t cmd = RecvByte();

	//prt("CMD: "); PrtHex(cmd); prt("\r\n");
	byte resp = RESP_ERROR;
	if (cmd >= CMD_FOPEN && cmd <= CMD_READDIR)
	{
		// call the command function
		resp = cmds[cmd - CMD_FOPEN]();
	}
	else
	{
	   prt("CMD Unknown ");
	   PrtHex(cmd);
	}
	SendByte(resp);	// response from the command or RESP_ERROR if command is unknown
}


