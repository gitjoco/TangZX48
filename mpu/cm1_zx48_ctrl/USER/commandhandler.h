/*
 * commandhandler.h
 *
 *  Created on: Feb 25, 2022
 *      Author: joco


 Copyright (c) 2016-2024 Jozsef Laszlo (rbendr@gmail.com)

*/

#ifndef __COMMANDHANDLER_H__
#define __COMMANDHANDLER_H__

#include "GOWIN_M1.h"

#include <stdlib.h>
#include <string.h>
#include "../FAT/ff.h"

#define CMD_FOPEN	0x10
#define CMD_FCREATE	0x11
#define CMD_FCLOSE	0x12
#define CMD_READ	0x13
#define CMD_WRITE	0x14
#define CMD_TEXT	0x15
#define CMD_ECHO	0x16

#define CMD_CD	0x17
#define CMD_OPENDIR	0x18
#define CMD_CLOSEDIR	0x19
#define CMD_READDIR	0x1a

#define RESP_OK		0x80
#define RESP_ERROR	0x7f
#define RESP_TEXT	0x02
#define RESP_DATA	0x03
#define CMD_CANCEL	0x04
#define RESP_EOS	0x05
#define CMD_PAUSE	0x06
#define CMD_RESUME	0x07
#define RESP_ROOT	0x08
#define RESP_MEMR	0x09
#define RESP_MEMW	0x0a
#define RESP_Z80ERR	0x0b


#define UDA         (*((volatile uint32_t *) 0x60000000))
#define UDCW        (*((volatile uint32_t *) 0x60000004))
#define CCDI        (*((volatile uint32_t *) 0x60000008))

extern FATFS FatFs;	// FatFs work area needed for each volume
extern FIL   File;		// File object needed for each open file
extern DIR   dir;

void prt(const char* s);

typedef uint8_t byte;
typedef byte (*funcPtr)();
typedef byte(*funcPtr2)(char* p);

uint8_t CommandPending();
int SendRecv(int b);
void HandleCommand();

#endif /* __COMMANDHANDLER_H__ */
