# * Data
#   * SET value, register
#   * MOV memloc, register // MOV register, memloc
#   * DIS (display)
# * Arith
#   * ADD, SUB, MUL, DIV
#   * bitwise operations (shl, shr, ^, &, |, ~)
#   * compare
# * control flow
#   * direct jump: jmp
#   * conditional jump: if-zero, if-negative

class Context
  attr_reader :instrs
  attr_reader :registers
  attr_reader :memory

  def initialize(instrs)
    @instrs = instrs
    @registers = { pc: 0 }
    @memory = {}
  end
end

def value_or_register(r, ctx)
  case r
  when Numeric
    r
  when Symbol
    ctx.registers[r]
  end
end

# MOV <mem-loc> <register>
# MOV <register> <mem-loc>

# ADD <value-or-register> <value-or-register> <register>
# SUB <value-or-register> <value-or-register> <register>
# MUL <value-or-register> <value-or-register> <register>
# DIV <value-or-register> <value-or-register> <register>
# MOD <value-or-register> <value-or-register> <register>

# SHL <value-or-register> <value-or-register> <register>
# SHR <value-or-register> <value-or-register> <register>

# XOR <value-or-register> <value-or-register> <register>
# AND <value-or-register> <value-or-register> <register>
# NOT <value-or-register> <value-or-register> <register>
# OR  <value-or-register> <value-or-register> <register>

# IZ  <value-or-register>
# INZ <value-or-register>

# DIS <value>
# DIS <register>
def dis(arg, ctx)
  case arg
  when Numeric
    puts arg
  when Symbol
    puts ctx.registers[arg]
  end
end

def sub(a, b, dst, ctx)
  a = value_or_register(a, ctx)
  b = value_or_register(b, ctx)

  ctx.registers[dst] = a - b
end

def halt(ctx)
  ctx.registers[:pc] -= 1
end

# SET <value> <register>
# SET <register> <register>
def set(src, dst, ctx)
  # TODO: allow register src
  ctx.registers[dst] = src
end

def eql(a, b, dst, ctx)
  a = value_or_register(a, ctx)
  b = value_or_register(b, ctx)

  ctx.registers[dst] = (a == b ? 1 : 0)
end

def ifnz(r, ctx)
  if ctx.registers[r] == 1
    ctx.registers[:pc] += 1
  end
end

def eval(instrs, ctx)
  instr = ctx.instrs[ctx.registers[:pc]]

  if instr.nil?
    raise "No instruction at #{ctx.registers[:pc]}"
  end

  puts "- #{instr[0].to_s.upcase}"
  case instr[0]
  when :dis
    dis(instr[1], ctx)
  when :set
    set(instr[1], instr[2], ctx)
  when :sub
    sub(instr[1], instr[2], instr[3], ctx)
  when :eql
    eql(instr[1], instr[2], instr[3], ctx)
  when :ifnz
    ifnz(instr[1], ctx)
  when :halt
    halt(ctx)
  end

  ctx.registers[:pc] += 1
  sleep 0.01
end

instrs = {
  0 => [:set, 100, :a],
  1 => [:dis, :a],
  2 => [:sub, :a, -1, :a],
  3 => [:eql, :a, 110, :b],
  4 => [:ifnz, :b],
  5 => [:set, 0, :pc],
  6 => [:dis, 666],
  7 => [:halt],
}

ctx = Context.new(instrs)
loop do
  eval(instrs, ctx)
end
