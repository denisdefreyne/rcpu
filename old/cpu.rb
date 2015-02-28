require 'terminal-table'

class Label < Struct.new(:name)
  def inspect
    "label(#{name})"
  end
end

class Register < Struct.new(:name)
  def inspect
    "R#{name}"
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

PC = reg(:PC)
SP = reg(:SP)
R = reg(:R)
A = reg(:A)
B = reg(:B)
C = reg(:C)

class Context
  # instructions + static data + stack (stack grows upwards)
  attr_reader :mem

  attr_reader :registers

  def initialize(mem)
    @mem = mem
    @registers = {
      PC => 0,
      SP => mem.keys.max,
      R  => 0,
      A  => 0,
      B  => 0,
      C  => 0,
    }
  end

  def inspect
    rows = mem
      .map { |k,v| [k,v] }
      .zip(registers.to_a)
      .map { |x| [x[0][0], x[0][1].inspect, x[1] && x[1][0].name, x[1] && x[1][1]] }
    table = Terminal::Table.new(rows: rows, headings: ['mem loc', 'val', 'reg', 'val'])
    table.to_s
  end

  def get_reg(reg)
    @registers[reg]
  end

  def set_reg(reg, val)
    case val
    when Value
      @registers[reg] = val.value
    else
      @registers[reg] = val
    end
  end

  def update_reg(reg, &block)
    set_reg(reg, yield(get_reg(reg)))
  end
end

###############################################################################

class Interpreter
  attr_reader :ctx

  def initialize(ctx)
    @ctx = ctx
  end

  def run
    loop { step }
  end

  def step
    instr = ctx.mem[ctx.get_reg(PC)]

    if instr.nil?
      raise "No instruction at #{ctx.get_reg(PC)}"
    end

    # puts "=== Evaluating #{instr.inspect}"
    # puts "--- Context:"
    puts ctx.inspect
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
    if ctx.get_reg(r) == 0
      ctx.update_reg(PC) { |v| v + 1 }
    end
  end

  # IFZ <value-or-register>
  def ifz(r, ctx)
    if ctx.get_reg(r) != 0
      ctx.update_reg(PC) { |v| v + 1 }
    end
  end

  # PUSH <value-or-register>
  def push(a, ctx)
    new_sp = ctx.registers[SP] + 1
    ctx.registers[SP] = new_sp
    ctx.mem[new_sp] = resolve(a, ctx)
  end

  # POP <register>
  def pop(a, ctx)
    sp = ctx.registers[SP]
    sp_deref = ctx.mem[sp]
    ctx.set_reg(a, sp_deref)
    ctx.registers[SP] = sp - 1
  end
end

###############################################################################

class Assembler
  def assemble(procedures, data)
    labels = {}
    i = 0
    mem = {}

    # Build instrs and remember labels
    procedures.each do |name, sub_instrs|
      labels[name] = i
      sub_instrs.each do |sub_instr|
        mem[i] = sub_instr
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
    mem.each do |_, item|
      p item
      if item.is_a?(Array)
        item.each_with_index do |arg, idx|
          if arg.is_a?(Label)
            item[idx] = val(labels[arg.name])
          end
        end
      end
      p item
    end

    mem
  end
end

###############################################################################

class DSL
  attr_reader :instrs

  def self.define(&block)
    dsl = self.new
    dsl.instance_eval(&block)
    dsl.instrs
  end

  def initialize
    @instrs = {} # ordered!
  end

  def label(name, &block)
    @instrs[name] = []
    BlockDSL.define(@instrs[name]) { noop }
    BlockDSL.define(@instrs[name], &block)
  end
end

class BlockDSL
  def self.define(instrs, &block)
    self.new(instrs).instance_eval(&block)
  end

  def initialize(instrs)
    @instrs = instrs
  end

  def fmt(x)
    # @instrs << [:fmt, x]
  end

  def set(src, dst)
    @instrs << [:set, src, dst]
  end

  def dis(x)
    # @instrs << [:dis, x]
  end

  def add(a, b, r)
    @instrs << [:add, a, b, r]
  end

  def mod(a, b, r)
    @instrs << [:mod, a, b, r]
  end

  def ifz(x)
    @instrs << [:ifz, x]
  end

  def ifnz(x)
    @instrs << [:ifnz, x]
  end

  def halt
    @instrs << [:halt]
  end

  def push(x)
    @instrs << [:push, x]
  end

  def pop(r)
    @instrs << [:pop, r]
  end

  def noop
    @instrs << [:noop]
  end
end

###############################################################################

program = DSL.define do
  label(:main) do
    fmt label(:hello)
  end

  label(:count_init) do
    set val(100), A
  end

  label(:count) do
    # count
    dis A
    add A, val(1), A
    mod A, val(120), B
    ifnz B
    set label(:count), PC

    # calc gcd
    push val(42)
    push val(14)
    add PC, val(2), A # return address
    push A # return address
    set label(:gcd), PC # jump
    dis A

    # done
    fmt label(:bye)
    halt
  end

  label(:gcd) do
    pop R # return address
    pop A
    pop B
  end

  label(:gcd_loop) do
    mod A, B, C # A % B -> C
    set B, A    # B -> A
    set C, B    # C -> B
    ifnz B
    set label(:gcd_loop), PC # jump
    set R, PC
  end
end

data = {
  hello: 'Hello, world!',
  bye: 'Goodbye, world!',
}

mem = Assembler.new.assemble(program, data)
ctx = Context.new(mem)
interpreter = Interpreter.new(ctx)
interpreter.run
