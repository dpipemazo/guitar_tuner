################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/bist.c \
../src/d_usb.c \
../src/gpio_devices.c \
../src/memory.c \
../src/platform.c \
../src/quad_spi_if_0.c \
../src/sleep.c 

OBJS += \
./src/bist.o \
./src/d_usb.o \
./src/gpio_devices.o \
./src/memory.o \
./src/platform.o \
./src/quad_spi_if_0.o \
./src/sleep.o 

C_DEPS += \
./src/bist.d \
./src/d_usb.d \
./src/gpio_devices.d \
./src/memory.d \
./src/platform.d \
./src/quad_spi_if_0.d \
./src/sleep.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MicroBlaze gcc compiler'
	mb-gcc -Wall -O0 -g -c -fmessage-length=0 -I../../BIST_bsp_0/microblaze_0/include -mxl-pattern-compare -mcpu=v7.30.b -mno-xl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


