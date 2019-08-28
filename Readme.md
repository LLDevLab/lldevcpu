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

### Unconditional branch instruction

- Opcode: 000011
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are source register's address. In this register actual branch address is stored. Bits 21 – 0 are reserved.
- Description: Moves branch address from source register to Program Counter register.
- Example: br r0 
- Status flags affected: does not change status register flags.

## Related software

lldevcpu assembly language compiler is located [here](https://github.com/LLDevLab/LLDevCompiler.git)