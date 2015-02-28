# RCPU

_RCPU_ is a virtual machine emulator and assembler written in Ruby.

Very much work in progress.

## Instruction format

Instructions are of variable length. The first byte is the opcode.

* 0: nop
* 1: addi reg, imm
* 2: mod reg, reg
* 3: mov reg, reg
* 4: jrz reg, imm
* 5: movi reg, imm
* 6: jrb imm
* 7: halt
* 8: mod2 reg, reg, reg

## To do

* Allow 32-bit immediates
* Rearrange opcodes so they make more sense
* Add more opcodes
* Write assembler
