################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../main_loop.c \
../snprintf.c 

ASM_SRCS += \
../codecs.asm \
../esai.asm \
../serial.asm 

OBJS += \
./codecs.cln \
./esai.cln \
./main_loop.cln \
./serial.cln \
./snprintf.cln 


# Each subdirectory must supply rules for building sources it contributes
%.cln: ../%.asm
	@echo 'Building file: $<'
	@echo 'Invoking: 56K GCC Assembler'
	g563c -v -g -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

%.cln: ../%.c
	@echo 'Building file: $<'
	@echo 'Invoking: 56K GCC Compiler'
	g563c -g -fno-opt -fforce-addr -fkeep-inline-functions -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

snprintf.cln: ../snprintf.c
	@echo 'Building file: $<'
	@echo 'Invoking: 56K GCC Compiler'
	g563c -DNEED_SNPRINTF_ONLY -g -fno-opt -fforce-addr -fkeep-inline-functions -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


