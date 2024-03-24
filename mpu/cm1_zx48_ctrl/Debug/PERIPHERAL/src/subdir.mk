################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../PERIPHERAL/src/GOWIN_M1_can.c \
../PERIPHERAL/src/GOWIN_M1_ddr3.c \
../PERIPHERAL/src/GOWIN_M1_dualtimer.c \
../PERIPHERAL/src/GOWIN_M1_ethernet.c \
../PERIPHERAL/src/GOWIN_M1_gpio.c \
../PERIPHERAL/src/GOWIN_M1_i2c.c \
../PERIPHERAL/src/GOWIN_M1_misc.c \
../PERIPHERAL/src/GOWIN_M1_psram.c \
../PERIPHERAL/src/GOWIN_M1_rtc.c \
../PERIPHERAL/src/GOWIN_M1_sdcard.c \
../PERIPHERAL/src/GOWIN_M1_spi.c \
../PERIPHERAL/src/GOWIN_M1_spi_flash.c \
../PERIPHERAL/src/GOWIN_M1_timer.c \
../PERIPHERAL/src/GOWIN_M1_trng.c \
../PERIPHERAL/src/GOWIN_M1_uart.c \
../PERIPHERAL/src/GOWIN_M1_wdog.c 

OBJS += \
./PERIPHERAL/src/GOWIN_M1_can.o \
./PERIPHERAL/src/GOWIN_M1_ddr3.o \
./PERIPHERAL/src/GOWIN_M1_dualtimer.o \
./PERIPHERAL/src/GOWIN_M1_ethernet.o \
./PERIPHERAL/src/GOWIN_M1_gpio.o \
./PERIPHERAL/src/GOWIN_M1_i2c.o \
./PERIPHERAL/src/GOWIN_M1_misc.o \
./PERIPHERAL/src/GOWIN_M1_psram.o \
./PERIPHERAL/src/GOWIN_M1_rtc.o \
./PERIPHERAL/src/GOWIN_M1_sdcard.o \
./PERIPHERAL/src/GOWIN_M1_spi.o \
./PERIPHERAL/src/GOWIN_M1_spi_flash.o \
./PERIPHERAL/src/GOWIN_M1_timer.o \
./PERIPHERAL/src/GOWIN_M1_trng.o \
./PERIPHERAL/src/GOWIN_M1_uart.o \
./PERIPHERAL/src/GOWIN_M1_wdog.o 

C_DEPS += \
./PERIPHERAL/src/GOWIN_M1_can.d \
./PERIPHERAL/src/GOWIN_M1_ddr3.d \
./PERIPHERAL/src/GOWIN_M1_dualtimer.d \
./PERIPHERAL/src/GOWIN_M1_ethernet.d \
./PERIPHERAL/src/GOWIN_M1_gpio.d \
./PERIPHERAL/src/GOWIN_M1_i2c.d \
./PERIPHERAL/src/GOWIN_M1_misc.d \
./PERIPHERAL/src/GOWIN_M1_psram.d \
./PERIPHERAL/src/GOWIN_M1_rtc.d \
./PERIPHERAL/src/GOWIN_M1_sdcard.d \
./PERIPHERAL/src/GOWIN_M1_spi.d \
./PERIPHERAL/src/GOWIN_M1_spi_flash.d \
./PERIPHERAL/src/GOWIN_M1_timer.d \
./PERIPHERAL/src/GOWIN_M1_trng.d \
./PERIPHERAL/src/GOWIN_M1_uart.d \
./PERIPHERAL/src/GOWIN_M1_wdog.d 


# Each subdirectory must supply rules for building sources it contributes
PERIPHERAL/src/%.o: ../PERIPHERAL/src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GNU ARM Cross C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m1 -mthumb -O3 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -I"E:\shared\gmd_ws\cm1_zx48_ctrl\CORE" -I"E:\shared\gmd_ws\cm1_zx48_ctrl\PERIPHERAL\inc" -I"E:\shared\gmd_ws\cm1_zx48_ctrl\SYSTEM" -I"E:\shared\gmd_ws\cm1_zx48_ctrl\USER" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


