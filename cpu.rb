# To do:
#
# - access memory (mov)
# - static data (strings)

class Label < Struct.new(:name)
  def inspect
    "label(#{name})"
  end
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

def label(name)
  Label.new(name)
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
  attr_reader :mem
  attr_reader :registers
  attr_reader :stack

  def initialize(instrs, mem)
    @instrs = instrs
    @mem = mem
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

###############################################################################

class Interpreter
  attr_reader :instrs
  attr_reader :ctx

  def initialize(ctx)
    @ctx = ctx
  end

  def run
    loop { step }
  end

  def step
    instr = ctx.instrs[ctx.get_reg(PC)]

    if instr.nil?
      raise "No instruction at #{ctx.get_reg(PC)}"
    end

    puts "--- STACK:     #{ctx.stack.inspect}"
    puts "--- REGISTERS: #{ctx.registers.inspect}"
    puts "--- Evaluating #{instr.inspect}"
    case instr[0]
    when :dis
      dis(instr[1], ctx)
    when :fmt
      fmt(instr[1], ctx)
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

    ctx.update_reg(PC) { |v| v + 1 }
    sleep 0.01
  end

  private

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

  # DIS <value-or-register>
  def dis(arg, ctx)
    puts resolve(arg, ctx)
  end

  # FMT <value-or-register>
  def fmt(arg, ctx)
    puts ctx.mem[resolve(arg, ctx)]
  end

  # ADD <value-or-register> <value-or-register> <register>
  def add(a, b, dst, ctx)
    a = resolve(a, ctx)
    b = resolve(b, ctx)

    ctx.set_reg(dst, a + b)
  end

  # SUB <value-or-register> <value-or-register> <register>
  def sub(a, b, dst, ctx)
    a = resolve(a, ctx)
    b = resolve(b, ctx)

    ctx.set_reg(dst, a - b)
  end

  # MUL <value-or-register> <value-or-register> <register>
  # DIV <value-or-register> <value-or-register> <register>

  # MOD <value-or-register> <value-or-register> <register>
  def mod(a, b, dst, ctx)
    a = resolve(a, ctx)
    b = resolve(b, ctx)

    ctx.set_reg(dst, a % b)
  end

  # SHL <value-or-register> <value-or-register> <register>
  # SHR <value-or-register> <value-or-register> <register>

  # XOR <value-or-register> <value-or-register> <register>
  # AND <value-or-register> <value-or-register> <register>
  # NOT <value-or-register> <value-or-register> <register>
  # OR  <value-or-register> <value-or-register> <register>

  # HALT
  def halt(ctx)
    ctx.update_reg(PC) { |v| v - 1 }
  end

  # SET <value-or-register> <register>
  def set(src, dst, ctx)
    ctx.set_reg(dst, resolve(src, ctx))
  end

  # MOV <mem-loc> <register>
  # …

  # MOV <register> <mem-loc>
  # …

  # EQL <value-or-register> <value-or-register> <register>
  def eql(a, b, dst, ctx)
    a = resolve(a, ctx)
    b = resolve(b, ctx)

    ctx.set_reg(dst, (a == b ? 1 : 0))
  end

  # IFNZ <value-or-register>
  def ifnz(r, ctx)
    if ctx.get_reg(r) != 0
      ctx.update_reg(PC) { |v| v + 1 }
    end
  end

  # IFZ <value-or-register>
  def ifz(r, ctx)
    if ctx.get_reg(r) == 0
      ctx.update_reg(PC) { |v| v + 1 }
    end
  end

  # PUSH <value-or-register>
  def push(a, ctx)
    ctx.stack.push(resolve(a, ctx))
  end

  # POP <register>
  def pop(a, ctx)
    ctx.set_reg(a, ctx.stack.pop)
  end
end

###############################################################################

program = {
  main: [
    # greet
    [:fmt, label(:hello)],
  ],
  count: [
    # count
    [:set, val(100), A],
    [:dis, A],
    [:add, A, val(1), A],
    [:mod, A, val(20), B],
    [:ifz, B],
    [:set, label(:count), PC],

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

data = {
  hello: "Hello, world!"
}

def translate(procedures, data)
  labels = {}
  i = 0
  instrs = {}
  mem = {}

  # Build instrs and remember labels
  procedures.each do |name, sub_instrs|
    labels[name] = i
    sub_instrs.each do |sub_instr|
      instrs[i] = sub_instr
      i += 1
    end
  end

  # Get data labels
  data.each do |name, value|
    labels[name] = i
    mem[i] = value
    i += 1
  end

  # Translate labels
  instrs.each do |_, instr|
    instr.each_with_index do |arg, idx|
      if arg.is_a?(Label)
        instr[idx] = val(labels[arg.name])
      end
    end
  end

  [instrs, mem]
end

instrs, mem = *translate(program, data)

ctx = Context.new(instrs, mem)
interpreter = Interpreter.new(ctx)
interpreter.run
