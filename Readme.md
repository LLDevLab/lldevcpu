# lldevcpu SoPC

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

## Supported Instructions

### Add instruction

- Opcode: 000001
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: Adds source register's value to destination register's value and puts the result to destination register.
- Example: add r0, r1

### Sub instruction

- Opcode: 000010
- Binary representation: Bits 31 – 26 are operation code (opcode), bits 25 – 22 are destination register's address and bits 21 – 18 are source registers address. Other bits are reserved.
- Description: Subtracts source register's value from destination register's value and puts the result to destination register.
- Example: sub r0, r1