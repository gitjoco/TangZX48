//
// Copyright (c) 2016-2024 Jozsef Laszlo (rbendr@gmail.com)
//


/* header file for load save old SNA snapsot files */

#include "GOWIN_M1.h"

#include <stdlib.h>
#include <string.h>
#include "../FAT/ff.h"

typedef uint8_t byte;

typedef struct {
	byte	I;
	byte	L2,H2,E2,D2,C2,B2,F2,A2;
	byte	L,H,E,D,C,B,YL,YH,XL,XH;
	byte	Interrupt;	/* bit #2: EI/DI  */
	byte	R;
	byte	F,A,SPL,SPH;
	byte	IntMode;	/* 0, 1, 2 */
	byte	BorderColor;	/* 0..7 */
} SNAheader;

typedef struct {
	byte A, F, C, B, L, H;
	byte PCL, PCH, SPL, SPH, I, R;
	byte flags;
	byte E, D, C2, B2, E2, D2, L2, H2;
	byte A2, F2, YL, YH, XL, XH;
	byte DIEI, IFF2;
	byte flags2;
} Z80header;

char* isZ80Sna(char* str);
int LoadZ80asSNA(FIL* f);
int IsZ80Snap48K(const char* filename);
