/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2021 Gowin Semiconductor Technology Co.,Ltd.
 * 		
 * @file		main.c
 * @author		Embedded Development Team
 * @version		V1.6.1
 * @date		2021-01-01 09:00:00
 * @brief		Main function.


  Copyright (c) 2016-2024 Jozsef Laszlo (rbendr@gmail.com)



 ******************************************************************************************
 */

/* Includes ------------------------------------------------------------------*/
#include "GOWIN_M1.h"
#include "GOWIN_M1_uart.h"
#include "GOWIN_M1_spi.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "commandhandler.h"
#include "../FAT/ff.h"

/* Declarations ------------------------------------------------------------------*/
void delay(__IO uint32_t nCount);

void SPIxInit();

__attribute__ ((used))  int _write (int fd, char *ptr, int len)
{
  size_t i;

  for (i=0; i<len; i++)
  {
    UART_SendChar(UART0,ptr[i]); // call character output function
  }

  return len;
}

void UartInit(void)
{
  UART_InitTypeDef UART_InitStruct;

  UART_InitStruct.UART_Mode.UARTMode_Tx = ENABLE;
  UART_InitStruct.UART_Mode.UARTMode_Rx = ENABLE;
  UART_InitStruct.UART_Int.UARTInt_Tx = DISABLE;
  UART_InitStruct.UART_Int.UARTInt_Rx = DISABLE;
  UART_InitStruct.UART_Ovr.UARTOvr_Tx = DISABLE;
  UART_InitStruct.UART_Ovr.UARTOvr_Rx = DISABLE;
  UART_InitStruct.UART_Hstm = DISABLE;
  UART_InitStruct.UART_BaudRate = 115200;//Baud Rate

  UART_Init(UART0,&UART_InitStruct);
}

void prt(const char* s)
{
	UART_SendString(UART0,(char *)s);
}

uint32_t  uda = 0x00000000;
uint32_t udcw = 0x00000003;
// cpustop <= APB1PWDATA(0);
//     uwr <= APB1PWDATA(1);
//   zxres <= APB1PWDATA(2);
//  ramres <= APB1PWDATA(3);


FATFS FatFs;	// FatFs work area needed for each volume


int main(void)
{
	char lb[64];
	int  lbidx=0;
	char c;

	SystemInit();	//Initializes system clock
	UartInit();
	SPIxInit();

	udcw = 0x02;
	UDCW=udcw;		// reset cpu, reset ram, cpu stop

	FRESULT res;
	char buff[8];

	printf("Try SD card mount first\n");
	res = f_mount(&FatFs, "", 1);
	if (res == FR_OK) {
		prt("f_mount ok\n");
	}
	else
	{
		prt("f_mount failed\n");
	}

	printf("ZX80 Ctrl System starts\n");
	while(1)
	{

		if (CommandPending())
		{
			HandleCommand();
		}
	}
}

//delay
void delay(__IO uint32_t nCount)
{
	for(; nCount != 0; nCount--);
}
