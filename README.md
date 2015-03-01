# RCPU

_RCPU_ is a virtual machine emulator and assembler written in Ruby.

Very much work in progress.

## Usage

To assemble a file, use _rcpu-assemble_, passing the input filename (with the _rcs_ extension). This will generate a corresponding _rcb_ file. For example:

	% ./bin/rcpu-assemble samples/counter.rcs

To run a file, use _rcpu-emulate_, passing the input filename (with the _rcb_ extension). For example:

	% ./bin/rcpu-emulate samples/counter.rcb

The _rcs_ extension is used for **RC**PU **s**ource files, while _rcb_ is for **RC**PU **b**inary (i.e. compiled) files.

## Registers

| Name   | Code | Size (bytes) | Purpose
| ------ | ---- | ------------ | -------
| r0     | 0x00 | 4            | general-purpose
| r1     | 0x01 | 4            | general-purpose
| r2     | 0x02 | 4            | general-purpose
| r3     | 0x03 | 4            | general-purpose
| r4     | 0x04 | 4            | general-purpose
| r5     | 0x05 | 4            | general-purpose
| r6     | 0x06 | 4            | general-purpose
| r7     | 0x07 | 4            | general-purpose
| rpc    | 0x08 | 4            | program counter (a.k.a instruction pointer)
| rflags | 0x09 | 1            | contains result of `cmp(i)`
| rsp    | 0x0a | 4            | stack pointer
| rbp    | 0x0b | 4            | base pointer
| rr     | 0x0c | 4            | return value

## Instruction format

Instructions are of variable length. The first byte is the opcode.

| Mnemonic  | Opcode     | Arguments             | Effect
| --------- | ---------- | --------------------- | ------
| `nop`     | 0x00       | 0                     | nothing
| `halt`    | 0xff       | 0                     | stops emulation
| `pop`     | 0x05       | 1 (reg)               | pop into a0
| `prn`     | 0x0e       | 1 (reg)               | print a0
| `jmp`     | 0x06       | 1 (label)             | pc ← a0
| `je`      | 0x07       | 1 (label)             | if == then pc ← a0
| `jne`     | 0x08       | 1 (label)             | if != then pc ← a0
| `jg`      | 0x09       | 1 (label)             | if >  then pc ← a0
| `jge`     | 0x0a       | 1 (label)             | if >= then pc ← a0
| `jl`      | 0x0b       | 1 (label)             | if <  then pc ← a0
| `jle`     | 0x0c       | 1 (label)             | if <= then pc ← a0
| `push(i)` | 0x03, 0x04 | 1 (reg/imm)           | push a0 onto stack
| `not`     | 0x0d       | 2 (reg, reg)          | a0 ← ~a1
| `mov(i)`  | 0x0f, 0x10 | 2 (reg, reg/imm)      | a0 ← a1
| `cmp(i)`  | 0x11, 0x12 | 2 (reg, reg/imm)      | (see below)
| `mod(i)`  | 0x13, 0x14 | 2 (reg, reg, reg/imm) | a0 ← a1 % a2
| `add(i)`  | 0x15, 0x16 | 2 (reg, reg, reg/imm) | a0 ← a1 + a2
| `sub(i)`  | 0x17, 0x18 | 2 (reg, reg, reg/imm) | a0 ← a1 - a2
| `mul(i)`  | 0x19, 0x1a | 2 (reg, reg, reg/imm) | a0 ← a1 * a2
| `div(i)`  | 0x1b, 0x1c | 2 (reg, reg, reg/imm) | a0 ← a1 / a2
| `xor(i)`  | 0x1d, 0x1e | 2 (reg, reg, reg/imm) | a0 ← a1 ^ a2
| `or(i)`   | 0x1f, 0x20 | 2 (reg, reg, reg/imm) | a0 ← a1 \| a2
| `and(i)`  | 0x21, 0x22 | 2 (reg, reg, reg/imm) | a0 ← a1 & a2
| `shl(i)`  | 0x23, 0x24 | 2 (reg, reg, reg/imm) | a0 ← a1 << a2
| `shr(i)`  | 0x24, 0x24 | 2 (reg, reg, reg/imm) | a0 ← a1 >> a2

`cmp(i)` updates the `flags` register and sets the 0x01 bit to true if the arguments are equal, and the 0x02 bit to true if the first argument is greater than the second.

Several opcodes have an `(i)` variant. These variants take a four-byte immediate argument (meaning the data is encoded in the instruction) rather than a register name. For opcodes that have immediate variants, the _Opcode_ column contains the non-immediate variant followed by the immediate variant.

## To do

* Finish implementing all opcodes
* Implement accessing memory using `[r0]`
