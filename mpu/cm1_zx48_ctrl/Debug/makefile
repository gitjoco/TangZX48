################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include USER/subdir.mk
-include SYSTEM/subdir.mk
-include STARTUP/subdir.mk
-include PERIPHERAL/src/subdir.mk
-include FAT/subdir.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(ASM_DEPS)),)
-include $(ASM_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
endif

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 
SECONDARY_FLASH += \
cm1_zx48_ctrl.bin \

SECONDARY_SIZE += \
cm1_zx48_ctrl.siz \


# All Target
all: cm1_zx48_ctrl.elf secondary-outputs

# Tool invocations
cm1_zx48_ctrl.elf: $(OBJS) $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: GNU ARM Cross C Linker'
	arm-none-eabi-gcc -mcpu=cortex-m1 -mthumb -O3 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -T "C:\GMD\workspace\cm1_zx48_ctrl\GOWIN_M1_flash.ld" -Xlinker --gc-sections -Wl,-Map,"cm1_zx48_ctrl.map" --specs=nano.specs -o "cm1_zx48_ctrl.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

cm1_zx48_ctrl.bin: cm1_zx48_ctrl.elf
	@echo 'Invoking: GNU ARM Cross Create Flash Image'
	arm-none-eabi-objcopy -O binary "cm1_zx48_ctrl.elf"  "cm1_zx48_ctrl.bin"
	@echo 'Finished building: $@'
	@echo ' '

cm1_zx48_ctrl.siz: cm1_zx48_ctrl.elf
	@echo 'Invoking: GNU ARM Cross Print Size'
	arm-none-eabi-size --format=berkeley "cm1_zx48_ctrl.elf"
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS)$(SECONDARY_FLASH)$(SECONDARY_SIZE)$(ASM_DEPS)$(S_UPPER_DEPS)$(C_DEPS) cm1_zx48_ctrl.elf
	-@echo ' '

secondary-outputs: $(SECONDARY_FLASH) $(SECONDARY_SIZE)

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
