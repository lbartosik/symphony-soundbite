################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
ASM_SRCS += \
../dsp_crt0.asm 

OBJS += \
./dsp_crt0.cln 


# Each subdirectory must supply rules for building sources it contributes
%.cln: ../%.asm
	@echo 'Building file: $<'
	@echo 'Invoking: 56K ASM Assembler'
	asm56300 -G -L% -B"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


