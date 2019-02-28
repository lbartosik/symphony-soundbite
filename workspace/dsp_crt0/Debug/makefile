################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -f

# All of the sources participating in the build are defined here
-include sources.mk
-include subdir.mk
-include objects.mk

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 

# All Target
all: pre-build main-build

# Main-build Target
main-build: Led.cld

# Tool invocations
Led.cld: $(OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: 56K ASM Linker'
	dsplnk -G -B"Led.cld" $(OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

# Other Targets
clean:
	$(RM) $(OBJS)$(EXECUTABLES) Led.cld
	-@echo ' '

pre-build:
	make clean
	-@echo ' '

.PHONY: all clean dependents
.SECONDARY: main-build pre-build

-include ../makefile.targets
