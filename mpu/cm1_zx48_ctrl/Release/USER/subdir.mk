################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../USER/GOWIN_M1_it.c \
../USER/commandhandler.c \
../USER/main.c \
../USER/snaps.c 

OBJS += \
./USER/GOWIN_M1_it.o \
./USER/commandhandler.o \
./USER/main.o \
./USER/snaps.o 

C_DEPS += \
./USER/GOWIN_M1_it.d \
./USER/commandhandler.d \
./USER/main.d \
./USER/snaps.d 


# Each subdirectory must supply rules for building sources it contributes
USER/%.o: ../USER/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GNU ARM Cross C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


