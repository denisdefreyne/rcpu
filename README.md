# RCPU

_RCPU_ is a virtual machine emulator and assembler written in Ruby.

Very much work in progress.

## Instruction format

Instructions are of variable length. The first byte is the opcode.

No args:

* `nop`
* `pushf`
* `call`
* `ret`

One register arg: (POSSIBLY also immediate)

* `push`: push a0
* `pop`:  pop a0
* `jmp`:  pc ← a0
* `je`:   if flags & 0x01 == 0x01: pc ← a0
* `jne`:  if flags & 0x01 == 0x00: pc ← a0
* `jg`:   if flags & 0x02 == 0x02: pc ← a0
* `jge`:  if flags & 0x03 != 0x00: pc ← a0
* `jl`:   if flags & 0x03 == 0x00: pc ← a0
* `jle`:  if flags & 0x02 == 0x00: pc ← a0
* `not`:  a0 ← ~a0
* `prn`:  (print a0)

One register and one immediate/register arg:

* `mov(i)`: a0 ← a1
* `cmp(i)`: flags ← (a0 == a1 ? 0x01 : 0x00) | (a0 > a1 ? 0x02 : 0x00)

Two register and one immediate/register arg:

* `mod(i)`: a0 ← a1 % a2
* `add(i)`: a0 ← a1 + a2
* `sub(i)`: a0 ← a1 - a2
* `mul(i)`: a0 ← a1 * a2
* `div(i)`: a0 ← a1 / a2
* `xor(i)`: a0 ← a1 ^ a2
* `or(i)`:  a0 ← a1 | a2
* `and(i)`: a0 ← a1 & a2
* `shl(i)`: a0 ← a1 << a2
* `shr(i)`: a0 ← a1 >> a2

## To do

* Finish implementing all opcodes
