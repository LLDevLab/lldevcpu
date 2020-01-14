# lldevcpu processor

## About project

In this project I'm trying to create custom SoPC (System on Programmable Chip) based on FPGA. This project is tested on Altera Cyclone II 
FPGA based board.

## CPU Design

CPU have 13 32bit general purpose registers (r0 - r12), as well as Status Register (r13), Stack Pointer Register (r14) and Program Counter Register (r15).

Each instruction in CPU is 32 bit long.

## CPU Pipeline

CPU have 2 stage pipeline:
- Fetch instruction from ROM memory
- Execute the instruction. Execution of instruction internally separated into 3 phases (each phase is taking 1 clock cycle):
	- Decoding phase. CPU is decoding instruction.
	- Executing phase. CPU is executing instruction. 
	- Write back. CPU is writing result back to destination register (if needed).

## Status register (r13) bits

- Bit 31 - Carry flag
	- Indicates a carry in an operation.
- Bit 30 - Zero flag 
	- Indicate whether or not operation result is zero. If result of operation is equal to 0, than flag is set, otherwise flag is clear.
- Bit 29 - Negative flag 
	- Indicate whether or not operation result is negative. Flag is set if MSB of the result is set, otherwise flag is clear.
	
## Memory mapping

### ROM memory 

ROM memory mapped to addresses starting from 0x10000000.

### RAM memory

RAM memory mapped to addresses starting from 0x20000000.

### Peripherials

Peripherial registers mapped to addresses starting from 0x30000000.

#### UART Control register
- 16 bit register to set up UART interface
- Offset: 0x0000
- Bit 15: tx enable bit
- Bit 14: rx enable bit
- Bits 13 - 11: Boud rate (at 50Mhz clock):
	- 000 - 9600
	- 001 - reserved
	- 010 - reserved
	- 011 - reserved
	- 100 - reserved
	- 101 - reserved
	- 110 - 115200
	- 111 - reserved
- Bit 12: Send data bit. Setting this bit to 1, will start transferring data
	
#### UART data output register
- 16 bit register to store outgoing data
- Offset: 0x0001

#### UART Status register
- 16 bit read-only register, where UART status are mapped
- Offset: 0x0003
- Bit 15: UART TX status
	- 0: TX is not ready
	- 1: TX is ready
- Bit 14: Transmission start bit
	- 0: Indicate, that transmission of data bit haven't been started
	- 1: Indicate, that transmission of data bit have been started. To transfer next byte of data, bit 12 in UART Control register should be cleared and set to 1 again

#### I2C Control register
- 16 bit register to set up I2C interface
- Offset: 0x0004
- Bit 15: tx enable bit
- Bit 14: rx enable bit
- Bits 13 - 11: Clock rate (at 50Mhz clock):
	- 000 - 1Mhz
	- 001 - reserved
	- 010 - reserved
	- 011 - reserved
	- 100 - reserved
	- 101 - reserved
	- 110 - reserved
	- 111 - reserved
- Bit 12: Send data bit. Setting this bit to 1, will start transferring data
- Bit 11: Transmitting data length
	- 0 - 8 bit
	- 1 - reserved

#### I2C address register
- 16 bit register. If device is a master, least significant byte of this register holds address of slave device. 
If device is a slave, least significant byte of this register holds device's address.
- Offset: 0x0005

#### I2C data input/output register
- 16 bit register, that holds incoming or outgoing data.
- Offset: 0x0006

#### I2C Status register
- 16 bit read-only register, where I2C status are mapped
- Offset: 0x0007
- Bit 15: I2C interface status
	- 0: I2C is not ready
	- 1: I2C is ready
- Bit 14: Transmission start bit
	- 0: Indicate, that transmission of data bit haven't been started
	- 1: Indicate, that transmission of data bit have been started. To transfer next byte of data, bit 12 in I2C Control register should be cleared and set to 1 again

## Supported Instructions

### Noop instruction

- Opcode: 000000
- Binary representation: Bits 31 – 26 are operation code (opcode), other bits values are ignored.
- Description: This instruction doesn't do anything.
- Example: noop
- Status flags affected: clears all status flags

### Add instruction

- Opcode: 000001
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: Adds source register's value to destination register's value and puts the result to destination register.
- Example: add r0, r1
- Status flags affected: Can affect carry, zero and negative flags

### Subtract instruction

- Opcode: 000010
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: Subtracts source register's value from destination register's value and puts the result to destination register.
- Example: sub r0, r1
- Status flags affected: Can affect carry, zero and negative flags

### Unconditional branch instruction (br)

- Opcode: 000011
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are source register's address. In this register actual branch address is stored. Bits 21 – 0 are reserved.
- Description: Moves branch address from source register to Program Counter register.
- Example: br r0 
- Status flags affected: does not change status register flags.

### Branch if equal instruction (breq)

- Opcode: 000100
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are source register's address. In this register actual branch address is stored. Bits 21 – 0 are reserved.
- Description: Moves branch address from source register to Program Counter register, if zero flag in status register is set.
- Example: breq r0 
- Status flags affected: does not change status register flags.

### Branch not if equal instruction (brne)

- Opcode: 000101
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are source register's address. In this register actual branch address is stored. Bits 21 – 0 are reserved.
- Description: Moves branch address from source register to Program Counter register, if zero flag in status register is not set.
- Example: brne r0 
- Status flags affected: does not change status register flags.

### Branch if less than instruction (for signed integers) (brlts)

- Opcode: 000110
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are source register's address. In this register actual branch address is stored. Bits 21 – 0 are reserved.
- Description: This instruction is using with signed integer numbers. It moves branch address from source register to Program Counter register, if negative flag in status register is set (value in rd register was less than value in rs register).
- Example: brlts r0 
- Status flags affected: does not change status register flags.

### Branch if greater than instruction (for signed integers) (brgts)

- Opcode: 000111
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are source register's address. In this register actual branch address is stored. Bits 21 – 0 are reserved.
- Description: This instruction is using with signed integer numbers. It moves branch address from source register to Program Counter register, if negative flag in status register is not set (value in rd register was greater than value in rs register).
- Example: brgts r0 
- Status flags affected: does not change status register flags.

### Branch if less than instruction (for unsigned integers) (brltu)

- Opcode: 001000
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are source register's address. In this register actual branch address is stored. Bits 21 – 0 are reserved.
- Description: This instruction is using with unsigned integer numbers. It moves branch address from source register to Program Counter register, if carry flag in status register is set (value in rd register was less than value in rs register).
- Example: brltu r0 
- Status flags affected: does not change status register flags.

### Branch if greater than instruction (for unsigned integers) (brgtu)

- Opcode: 001001
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are source register's address. In this register actual branch address is stored. Bits 21 – 0 are reserved.
- Description: This instruction is using with unsigned integer numbers. It moves branch address from source register to Program Counter register, if carry flag in status register is not set (value in rd register was greater than value in rs register).
- Example: brgtu r0 
- Status flags affected: does not change status register flags.

### Compare instruction (cmp)
- Opcode: 001010
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: Subtracts source register's value from destination register's value and sets appropriate flags in Status register. Value in source and destination register will not be changed.
- Example: cmp r0, r1
- Status flags affected: Can affect carry, zero and negative flags

### Clear instruction (clr)
- Opcode: 001011
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address. Other bits are reserved.
- Description: Clears all bits in destination register.
- Example: clr r0
- Status flags affected: Carry and negative flags will be cleared, zero flag will be set.

### Load immediate instruction (ldi)
- Opcode: 001100
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address, bits 21 - 0 value of immediate number.
- Description: Clears all bits in destination register. Loads immediate number to a register. A number can be 22 bits long (0 – 4194303).
- Decimal example: ldi r0, #10
- Hexadecimal example: ldi r0, #0x10
- Status flags affected: does not change status register flags.

### OR instruction (or)
- Opcode: 001101
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: Doing bitwise OR operation on values from 2 registers (rd and rs) and storing the result to destination register (rd)
- Example: or r0, r1
- Status flags affected: Carry flag will be cleared, zero and negative flags values depends on destination register's value.

### AND instruction (and)
- Opcode: 001110
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: Doing bitwise AND operation on values from 2 registers (rd and rs) and storing the result to destination register (rd)
- Example: and r0, r1
- Status flags affected: Carry flag will be cleared, zero and negative flags values depends on destination register's value.

### XOR instruction (xor)
- Opcode: 001111
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: Doing bitwise XOR operation on values from 2 registers (rd and rs) and storing the result to destination register (rd)
- Example: xor r0, r1
- Status flags affected: Carry flag will be cleared, zero and negative flags values depends on destination register's value.

### NOT instruction (not)
- Opcode: 010000
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address. Other bits are reserved.
- Description: Doing bitwise NOT operation on value from destination register (rd) and storing the result to destination register (rd)
- Example: not r0
- Status flags affected: Carry flag will be cleared, zero and negative flags values depends on destination register's value.

### Lelf shift instruction (lsh)
- Opcode: 010001
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address, bits 21 - 17 value of immediate number. Other bits are reserved.
- Description: Doing bitwise left shift operation on value from destination register (rd) and storing the result to destination register (rd). An immediate number can be 5 bits long (0 – 31).
- Decimal example: lsh r0, #10
- Hexadecimal example: lsh r0, #0x10
- Status flags affected: Carry flag will be taken from the last shifted bit, zero and negative flags values depends on destination register's value.

### Right shift instruction (rsh)
- Opcode: 010010
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address, bits 21 - 17 value of immediate number. Other bits are reserved.
- Description: Doing bitwise right shift operation on value from destination register (rd) and storing the result to destination register (rd). An immediate number can be 5 bits long (0 – 31).
- Decimal example: rsh r0, #10
- Hexadecimal example: rsh r0, #0x10
- Status flags affected: Carry flag will be taken from the last shifted bit, zero and negative flags values depends on destination register's value.

### Rotate left instruction (rtl)
- Opcode: 010011
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address, bits 21 - 17 value of immediate number. Other bits are reserved.
- Description: Doing bitwise rotate left operation on value from destination register (rd) and storing the result to destination register (rd). An immediate number can be 5 bits long (0 – 31).
- Decimal example: rtl r0, #10
- Hexadecimal example: rtl r0, #0x10
- Status flags affected: Carry flag will be taken from result's zero bit, zero and negative flags values depends on destination register's value.

### Rotate right instruction (rtr)
- Opcode: 010100
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address, bits 21 - 17 value of immediate number. Other bits are reserved.
- Description: Doing bitwise rotate right operation on value from destination register (rd) and storing the result to destination register (rd). An immediate number can be 5 bits long (0 – 31).
- Decimal example: rtr r0, #10
- Hexadecimal example: rtr r0, #0x10
- Status flags affected: Carry flag will be taken from result's 31th bit, zero and negative flags values depends on destination register's value.

### Rotate left through carry bit instruction (rtlc)
- Opcode: 010101
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address, bits 21 - 17 value of immediate number. Other bits are reserved.
- Description: Doing bitwise rotate left operation, through carry bit (value from carry bit will also rotate left), on value from destination register (rd) and storing the result to destination register (rd). An immediate number can be 5 bits long (0 – 31).
- Decimal example: rtlc r0, #10
- Hexadecimal example: rtlc r0, #0x10
- Status flags affected: The last rotated bit will be moved to carry flag, zero and negative flags values depends on destination register's value.

### Rotate right through carry bit instruction (rtlc)
- Opcode: 010110
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address, bits 21 - 17 value of immediate number. Other bits are reserved.
- Description: Doing bitwise rotate right operation, through carry bit (value from carry bit will also rotate right), on value from destination register (rd) and storing the result to destination register (rd). An immediate number can be 5 bits long (0 – 31).
- Decimal example: rtrc r0, #10
- Hexadecimal example: rtrc r0, #0x10
- Status flags affected: The last rotated bit will be moved to carry flag, zero and negative flags values depends on destination register's value.

### Add through carry bit instruction

- Opcode: 010111
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: Adds source register's value to destination register's value, to the resulting value adds a carry bit and puts the final result to destination register.
- Example: addc r0, r1
- Status flags affected: Can affect carry, zero and negative flags

### Subtract through carry bit instruction

- Opcode: 011000
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: 
- Example: subc r0, r1
- Status flags affected: Can affect carry, zero and negative flags

### Load from memory address instruction

- Opcode: 011001
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: Loads data from memory address (that is stored in source register (rs)), to destination register (rd).
- Example: ld r0, r1
- Status flags affected: Flags are not affected

### Store to memory address instruction

- Opcode: 011010
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: Store data from source register (rs) to memory address (that is stored in destination register (rd)).
- Example: st r0, r1
- Status flags affected: Flags are not affected

### Move instruction

- Opcode: 011011
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: Move data from source register (rs) to destination register (rd).
- Example: mov r0, r1
- Status flags affected: Flags are not affected

### Push instruction

- Opcode: 011100
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are register's address. Other bits are reserved.
- Description: Store the content of register to the top of the stack.
- Example: push r0
- Status flags affected: Flags are not affected

### Pop instruction

- Opcode: 011101
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are register's address. Other bits are reserved.
- Description: Load content from the top of the stack to the register.
- Example: pop r0
- Status flags affected: Flags are not affected

### Call instruction

- Opcode: 011110
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address. Other bits are reserved.
- Description: Saves current programm counter register's value to the stack, decrements stack pointer registers's value and branches to the address from destination register (rd).
- Example: call r0
- Status flags affected: Flags are not affected

### Ret instruction

- Opcode: 011111
- Binary representation: Bits 31 – 26 are operation code (opcode). Other bits are reserved.
- Description: Restores return address from the stack to programm counter register and increments stack pointer register's value.
- Example: ret
- Status flags affected: Flags are not affected

## Related software

lldevcpu assembly language compiler is located [here](https://github.com/LLDevLab/LLDevCompiler.git)