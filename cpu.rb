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

def label(name)
  [:label, name]
end

class Register < Struct.new(:name)
  def inspect
    "reg(#{name})"
  end
end

class Value < Struct.new(:value)
  def inspect
    "val(#{value})"
  end
end

def reg(name)
  Register.new(name)
end

def val(value)
  Value.new(value)
end

A = reg(:a)
B = reg(:b)
C = reg(:c)
R = reg(:r)
PC = reg(:pc)

class Context
  attr_reader :instrs
  attr_reader :registers
  attr_reader :stack

  def initialize(instrs)
    @instrs = instrs
    @registers = { PC => val(0) }
    @stack = []
  end

  def get_reg(reg)
    v = @registers[reg]
    v && v.value
  end

  def set_reg(reg, val)
    case val
    when Value
      @registers[reg] = val
    else
      @registers[reg] = Value.new(val)
    end
  end

  def update_reg(reg, &block)
    set_reg(reg, yield(get_reg(reg)))
  end
end

def resolve(r, ctx)
  case r
  when Register
    ctx.get_reg(r)
  when Value
    r.value
  else
    raise "do not know how to resolve #{r.inspect}"
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
  puts resolve(arg, ctx)
end

def add(a, b, dst, ctx)
  p [a,b]
  a = resolve(a, ctx)
  b = resolve(b, ctx)
  p [a,b]

  ctx.set_reg(dst, a + b)
end

def sub(a, b, dst, ctx)
  a = resolve(a, ctx)
  b = resolve(b, ctx)

  ctx.set_reg(dst, a - b)
end

def mod(a, b, dst, ctx)
  a = resolve(a, ctx)
  b = resolve(b, ctx)

  ctx.set_reg(dst, a % b)
end

def halt(ctx)
  ctx.update_reg(PC) { |v| v - 1 }
end

# SET <value> <register>
# SET <register> <register>
def set(src, dst, ctx)
  p [:SET, src, dst, resolve(src, ctx), ctx.registers]
  ctx.set_reg(dst, resolve(src, ctx))
end

def eql(a, b, dst, ctx)
  a = resolve(a, ctx)
  b = resolve(b, ctx)

  ctx.set_reg(dst, (a == b ? 1 : 0))
end

def ifnz(r, ctx)
  if ctx.get_reg(r) != 0
    ctx.update_reg(PC) { |v| v + 1 }
  end
end

def ifz(r, ctx)
  if ctx.get_reg(r) == 0
    ctx.update_reg(PC) { |v| v + 1 }
  end
end

def push(a, ctx)
  ctx.stack.push(resolve(a, ctx))
end

def pop(a, ctx)
  ctx.set_reg(a, ctx.stack.pop)
end

def eval(instrs, ctx)
  instr = ctx.instrs[ctx.get_reg(PC)]

  if instr.nil?
    raise "No instruction at #{ctx.get_reg(PC)}"
  end

  p instr
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
  when :noop
  end
  p [ctx.stack, ctx.registers]

  ctx.update_reg(PC) { |v| v + 1 }
  sleep 0.01
end

program = {
  main: [
    # count
    [:set, val(100), A],
    [:dis, A],
    [:add, A, val(1), A],
    [:mod, A, val(20), B],
    [:ifz, B],
    [:set, val(0), PC],

    # calc gcd
    [:push, val(42)],
    [:push, val(14)],
    [:add, PC, val(2), A], # return address
    [:push, A], # return address
    [:set, label(:gcd), PC], # jump
    [:dis, A],

    # done
    [:dis, val(666)],
    [:halt],
  ],
  gcd: [
    [:noop],
    [:pop, R], # return address
    [:pop, A],
    [:pop, B],
  ],
  gcd_loop: [
    [:mod, A, B, C],
    [:set, B, A],
    [:set, C, B],
    [:ifnz, C],
    [:set, label(:gcd_loop), PC], # jump
    [:set, R, PC],
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
        instr[idx] = val(labels[arg[1]])
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
