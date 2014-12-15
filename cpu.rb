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
  attr_reader :stack

  def initialize(instrs)
    @instrs = instrs
    @registers = { pc: 0 }
    @stack = []
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

def add(a, b, dst, ctx)
  a = value_or_register(a, ctx)
  b = value_or_register(b, ctx)

  ctx.registers[dst] = a + b
end

def sub(a, b, dst, ctx)
  a = value_or_register(a, ctx)
  b = value_or_register(b, ctx)

  ctx.registers[dst] = a - b
end

def mod(a, b, dst, ctx)
  a = value_or_register(a, ctx)
  b = value_or_register(b, ctx)

  ctx.registers[dst] = a % b
end

def halt(ctx)
  ctx.registers[:pc] -= 1
end

# SET <value> <register>
# SET <register> <register>
def set(src, dst, ctx)
  ctx.registers[dst] = value_or_register(src, ctx)
end

def eql(a, b, dst, ctx)
  a = value_or_register(a, ctx)
  b = value_or_register(b, ctx)

  ctx.registers[dst] = (a == b ? 1 : 0)
end

def ifnz(r, ctx)
  if ctx.registers[r] != 0
    ctx.registers[:pc] += 1
  end
end

def ifz(r, ctx)
  if ctx.registers[r] == 0
    ctx.registers[:pc] += 1
  end
end

def push(a, ctx)
  ctx.stack << value_or_register(a, ctx)
end

def pop(a, ctx)
  ctx.registers[a] = ctx.stack.pop
end

def eval(instrs, ctx)
  instr = ctx.instrs[ctx.registers[:pc]]

  if instr.nil?
    raise "No instruction at #{ctx.registers[:pc]}"
  end

  # p instr
  case instr[0]
  when :dis
    dis(instr[1], ctx)
  when :set
    set(instr[1], instr[2], ctx)
  when :sub
    sub(instr[1], instr[2], instr[3], ctx)
  when :add
    add(instr[1], instr[2], instr[3], ctx)
  when :eql
    eql(instr[1], instr[2], instr[3], ctx)
  when :ifnz
    ifnz(instr[1], ctx)
  when :ifz
    ifz(instr[1], ctx)
  when :halt
    halt(ctx)
  when :mod
    mod(instr[1], instr[2], instr[3], ctx)
  when :push
    push(instr[1], ctx)
  when :pop
    pop(instr[1], ctx)
  end

  ctx.registers[:pc] += 1
  sleep 0.01
end

def label(name)
  [:label, name]
end

program = {
  main: [
    [:set, 100, :a],
    [:dis, :a],
    [:add, :a, 1, :a],
    [:mod, :a, 20, :b],
    [:ifz, :b],
    [:set, 0, :pc],
    [:set, 42, :a],
    [:set, 14, :b],
    [:add, :pc, 2, :d], # return address
    [:push, :d], # return address
    [:set, label(:gcd), :pc], # jump
    [:dis, :a],
    [:dis, 666],
    [:halt],
  ],
  gcd: [
    [:mod, :a, :b, :c],
    [:set, :b, :a],
    [:set, :c, :b],
    [:ifnz, :c],
    [:set, label(:gcd), :pc], # jump
    [:pop, :pc],
  ]
}

def translate(procedures)
  # Build instrs
  instrs = []
  i = 0
  labels = {}
  procedures.each do |name, sub_instrs|
    labels[name] = i
    sub_instrs.each do |sub_instr|
      instrs[i] = sub_instr
      i += 1
    end
  end

  # Translate labels
  instrs.each do |instr|
    instr.each_with_index do |arg, idx|
      if arg.is_a?(Array) && arg[0] == :label
        instr[idx] = labels[arg[1]]
      end
    end
  end

  instrs
end

instrs = translate(program)
ctx = Context.new(instrs)
loop do
  eval(instrs, ctx)
end
