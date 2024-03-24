################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../SYSTEM/system_GOWIN_M1.c 

OBJS += \
./SYSTEM/system_GOWIN_M1.o 

C_DEPS += \
./SYSTEM/system_GOWIN_M1.d 


# Each subdirectory must supply rules for building sources it contributes
SYSTEM/%.o: ../SYSTEM/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GNU ARM Cross C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m1 -mthumb -O3 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -I"E:\shared\gmd_ws\cm1_zx48_ctrl\CORE" -I"E:\shared\gmd_ws\cm1_zx48_ctrl\PERIPHERAL\inc" -I"E:\shared\gmd_ws\cm1_zx48_ctrl\SYSTEM" -I"E:\shared\gmd_ws\cm1_zx48_ctrl\USER" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


