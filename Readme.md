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

### Sub instruction

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
- Status flags affected: Can affect carry, zero and negative flags

### AND instruction (and)
- Opcode: 001110
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: Doing bitwise AND operation on values from 2 registers (rd and rs) and storing the result to destination register (rd)
- Example: and r0, r1
- Status flags affected: Can affect carry, zero and negative flags

### XOR instruction (xor)
- Opcode: 001111
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: Doing bitwise XOR operation on values from 2 registers (rd and rs) and storing the result to destination register (rd)
- Example: xor r0, r1
- Status flags affected: Can affect carry, zero and negative flags

### NOT instruction (not)
- Opcode: 010000
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address. Other bits are reserved.
- Description: Doing bitwise NOT operation on value from destination register (rd) and storing the result to destination register (rd)
- Example: not r0
- Status flags affected: Can affect carry, zero and negative flags

### Lelf shift instruction (lsh)
- Opcode: 010001
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address, bits 21 - 17 value of immediate number. Other bits are reserved.
- Description: Doing bitwise left shift operation on value from destination register (rd) and storing the result to destination register (rd). An immediate number can be 5 bits long (0 – 31).
- Decimal example: lsh r0, #10
- Hexadecimal example: lsh r0, #0x10
- Status flags affected: Can affect carry, zero and negative flags.

## Related software

lldevcpu assembly language compiler is located [here](https://github.com/LLDevLab/LLDevCompiler.git)