class Arg
  def kind
    raise "Not implemented"
  end

  def valid?
    raise "Not implemented"
  end

  def bytes(_labels)
    raise "Not implemented"
    [] of UInt8
  end
end

class RegArg < Arg
  MAPPING = {
    "r0"     => 0.to_u8,
    "r1"     => 1.to_u8,
    "r2"     => 2.to_u8,
    "r3"     => 3.to_u8,
    "r4"     => 4.to_u8,
    "r5"     => 5.to_u8,
    "r6"     => 6.to_u8,
    "r7"     => 7.to_u8,
    "rpc"    => 8.to_u8,
    "rflags" => 9.to_u8,
    "rsp"    => 10.to_u8,
    "rbp"    => 11.to_u8,
    "rr"     => 12.to_u8,
  }

  getter :name

  def initialize(name)
    @name = name
  end

  def kind
    :register
  end

  def inspect
    "reg(#{@name})"
  end

  def valid?
    MAPPING.has_key?(name)
  end

  def bytes(_labels)
    [MAPPING.fetch(name)]
  end
end

class ImmArg < Arg
  getter :value

  def initialize(value)
    @value = value
  end

  def kind
    :immediate
  end

  def inspect
    "imm(#{@value})"
  end

  def valid?
    true
  end

  def bytes(_labels)
    [
      ((value & 0xff000000) >> 0x18).to_u8,
      ((value & 0x00ff0000) >> 0x10).to_u8,
      ((value & 0x0000ff00) >> 0x08).to_u8,
      ((value & 0x000000ff) >> 0x00).to_u8,
    ]
  end
end

# Inherits from ImmArg because this is a sort of unresolved immediate arg
class LabelArg < Arg
  getter :name

  def initialize(name)
    @name = name
  end

  def kind
    :immediate
  end

  def inspect
    "label(#{@name})"
  end

  def valid?
    true
  end

  def bytes(labels)
    if labels
      value = labels[name]
      [
        ((value & 0xff000000) >> 0x18).to_u8,
        ((value & 0x00ff0000) >> 0x10).to_u8,
        ((value & 0x0000ff00) >> 0x08).to_u8,
        ((value & 0x000000ff) >> 0x00).to_u8,
      ]
    else
      [0x00.to_u8, 0x00.to_u8, 0x00.to_u8, 0x00.to_u8]
    end
  end
end

###############################################################################

class Instruction
  getter :opcode_mnemonic
  getter :args

  def initialize(opcode_mnemonic, args)
    @opcode_mnemonic = opcode_mnemonic
    @args = args
  end

  def inspect
    "instr(#{@opcode_mnemonic}, args = #{@args.inspect})"
  end

  def instruction?
    true
  end

  def label?
    false
  end

  def data?
    false
  end
end

class Label
  getter :name

  def initialize(name)
    @name = name
  end

  def inspect
    "label(#{name.inspect})"
  end

  def instruction?
    false
  end

  def label?
    true
  end

  def data?
    false
  end
end

class DataDirective
  getter :length
  getter :arg

  def initialize(length, arg)
    @length = length
    @arg = arg
  end

  def inspect
    "data(arg=#{arg.inspect} length=#{length})"
  end

  def instruction?
    false
  end

  def label?
    false
  end

  def data?
    true
  end

  def bytes(labels)
    bytes = arg.bytes(labels)
    bytes.reverse.take(length).reverse
  end
end

###############################################################################

require "string_scanner"

class Token
  getter content

  def initialize(content)
    @content = content
  end
end

class IdentifierToken < Token
  REGEX = /[a-zA-Z]+[a-zA-Z0-9-]+/
end

class NumberToken < Token
  REGEX = /(|0|0x|0b)[0-9]+/
end

class DotToken < Token
  REGEX = /\./
end

class ColonToken < Token
  REGEX = /:/
end

class CommaToken < Token
  REGEX = /,/
end

class CommentToken < Token
  REGEX = /#.*/
end

class AtToken < Token
  REGEX = /@/
end

class SpaceToken < Token
  REGEX = /( |\t)+/
end

class NewlineToken < Token
  REGEX = /\n/
end

class Lexer2
  def initialize(input)
    @input = input
  end

  def run
    scanner = StringScanner.new(@input)
    tokens = [] of Token

    until scanner.eos?
      case
      when t = scanner.scan(IdentifierToken::REGEX)
        p t ; tokens << IdentifierToken.new(t)
      when t = scanner.scan(NumberToken::REGEX)
        p t ; tokens << NumberToken.new(t)
      when t = scanner.scan(DotToken::REGEX)
        p t ; tokens << DotToken.new(t)
      when t = scanner.scan(ColonToken::REGEX)
        p t ; tokens << ColonToken.new(t)
      when t = scanner.scan(CommaToken::REGEX)
        p t ; tokens << CommaToken.new(t)
      when t = scanner.scan(CommentToken::REGEX)
        p t ; tokens << CommentToken.new(t)
      when t = scanner.scan(AtToken::REGEX)
        p t ; tokens << AtToken.new(t)
      when t = scanner.scan(SpaceToken::REGEX)
        p t ; tokens << SpaceToken.new(t)
      when t = scanner.scan(NewlineToken::REGEX)
        p t ; tokens << NewlineToken.new(t)
      when t = scanner.scan(/./m)
        raise "Lexer error before #{t.inspect}"
      end
    end

    tokens
  end
end

# class NewParser
#   getter program

#   def initialize(input)
#     @input = input
#     @index = 0
#     @program = [] of Instruction | DataDirective | Label
#   end

#   def parse
#     case c = peek_char
#     when /\s/
#     when '.'
#     when /[a-z-]/
#     when nil
#       # done
#     else
#       raise "Illegal start of line: #{c}"
#     end
#   end

#   private def peek_char
#     @input[@index]
#   end

#   private def read_char
#     peek_char.tap { @index += 1 }
#   end
# end

class Parser
  def parse_raw_lines(raw_lines)
    puts "lexing…"
    res = Lexer2.new(raw_lines.join("\n")).run
    puts "done lexing"

    raw_lines.map { |rl| parse_raw_line(rl) }.compact
  end

  def parse_raw_line(raw_line)
    raw_line = raw_line.gsub(/#.*/, "")

    if raw_line.strip.empty?
      nil
    elsif raw_line =~ /\A\s+/
      parts = raw_line.strip.split(/ +/)

      opcode_mnemonic = parts[0]
      args = parts[1..-1].map { |s| parse_arg(s.gsub(/,\z/, "")) }

      Instruction.new(opcode_mnemonic, args)
    elsif raw_line.strip =~ /\A\.([a-z]+) (.*)/
      parse_directive($1, $2)
    else
      Label.new(raw_line.strip.gsub(/:\z/, ""))
    end
  end

  def parse_directive(raw_type, raw_value)
    value = parse_number(raw_value)
    arg =
      if value
        ImmArg.new(value)
      elsif raw_value =~ /\A@[a-z0-9-]+\z/
        LabelArg.new(raw_value[1..-1])
      else
        raise "Weird"
      end

    length =
      case raw_type
      when "byte"
        1
      when "half"
        2
      when "word"
        4
      else
        raise "Unrecognised directive: #{raw_type}"
      end

    DataDirective.new(length, arg)
  end

  def parse_number(string)
    case string
    when /\A0x[0-9a-fA-F]+\z/
      string[2..-1].to_i(16)
    when /\A0b[0-1]+\z/
      string[2..-1].to_i(2)
    when /\A\d+\z/
      string.to_i
    else
      nil
    end
  end

  def parse_arg(string)
    # Try as number
    number = parse_number(string)
    if number
      return ImmArg.new(number)
    end

    case string
    when /\A@[a-z0-9-]+\z/
      LabelArg.new(string[1..-1])
    when /\Ar[a-z0-9]+\z/
      RegArg.new(string)
    else
      raise "Cannot parse argument: #{string.inspect}"
    end
  end
end

class Assembler
  def initialize(raw_lines)
    @raw_lines = raw_lines
  end

  def assemble
    parser = Parser.new
    lines = parser.parse_raw_lines(@raw_lines)
    labels = collect_labels(lines)
    generate_program(lines, labels)
  end

  private def collect_labels(lines)
    labels = {} of String => UInt32
    program = [] of UInt8
    lines.each do |line|
      case line
      when Instruction
        handle_instruction(line, program, nil)
      when Label
        labels[line.name] = program.size.to_u32
      when DataDirective
        line.length.times { program << 0x00.to_u8 }
      end
    end
    labels
  end

  private def generate_program(lines, labels)
    program = [] of UInt8
    lines.each do |line|
      case line
      when Instruction
        handle_instruction(line, program, labels)
      when DataDirective
        line.bytes(labels).each { |byte| program << byte }
      end
    end
    program
  end

  class IDef
    getter :opcode
    getter :args

    def initialize(opcode : UInt8, args)
      @opcode = opcode
      @args   = args
    end
  end

  INSTRUCTION_DEFS = {
    "call"  => IDef.new(0x01.to_u8, [:immediate]),
    "ret"   => IDef.new(0x02.to_u8, [] of Symbol),
    "push"  => IDef.new(0x03.to_u8, [:register]),
    "pushi" => IDef.new(0x04.to_u8, [:immediate]),
    "pop"   => IDef.new(0x05.to_u8, [:register]),
    "jmpi"  => IDef.new(0x06.to_u8, [:immediate]), # FIXME: rearrange opcodes
    "jmp"   => IDef.new(0xa6.to_u8, [:register]),
    "je"    => IDef.new(0x07.to_u8, [:immediate]),
    "jne"   => IDef.new(0x08.to_u8, [:immediate]),
    "jg"    => IDef.new(0x09.to_u8, [:immediate]),
    "jge"   => IDef.new(0x0a.to_u8, [:immediate]),
    "jl"    => IDef.new(0x0b.to_u8, [:immediate]),
    "jle"   => IDef.new(0x0c.to_u8, [:immediate]),
    "not"   => IDef.new(0x0d.to_u8, [:register, :register]),
    "prn"   => IDef.new(0x0e.to_u8, [:register]),
    "cmp"   => IDef.new(0x11.to_u8, [:register, :register]),
    "cmpi"  => IDef.new(0x12.to_u8, [:register, :immediate]),
    "mod"   => IDef.new(0x13.to_u8, [:register, :register, :register]),
    "modi"  => IDef.new(0x14.to_u8, [:register, :register, :immediate]),
    "add"   => IDef.new(0x15.to_u8, [:register, :register, :register]),
    "addi"  => IDef.new(0x16.to_u8, [:register, :register, :immediate]),
    "sub"   => IDef.new(0x17.to_u8, [:register, :register, :register]),
    "subi"  => IDef.new(0x18.to_u8, [:register, :register, :immediate]),
    "mul"   => IDef.new(0x19.to_u8, [:register, :register, :register]),
    "muli"  => IDef.new(0x1a.to_u8, [:register, :register, :immediate]),
    "div"   => IDef.new(0x1b.to_u8, [:register, :register, :register]),
    "divi"  => IDef.new(0x1c.to_u8, [:register, :register, :immediate]),
    "xor"   => IDef.new(0x1d.to_u8, [:register, :register, :register]),
    "xori"  => IDef.new(0x1e.to_u8, [:register, :register, :immediate]),
    "or"    => IDef.new(0x1f.to_u8, [:register, :register, :register]),
    "ori"   => IDef.new(0x20.to_u8, [:register, :register, :immediate]),
    "and"   => IDef.new(0x21.to_u8, [:register, :register, :register]),
    "andi"  => IDef.new(0x22.to_u8, [:register, :register, :immediate]),
    "shl"   => IDef.new(0x23.to_u8, [:register, :register, :register]),
    "shli"  => IDef.new(0x24.to_u8, [:register, :register, :immediate]),
    "shr"   => IDef.new(0x25.to_u8, [:register, :register, :register]),
    "shri"  => IDef.new(0x26.to_u8, [:register, :register, :immediate]),
    "li"    => IDef.new(0x27.to_u8, [:register, :immediate]),
    "lw"    => IDef.new(0x28.to_u8, [:register, :register]),
    "lh"    => IDef.new(0x29.to_u8, [:register, :register]),
    "lb"    => IDef.new(0x2a.to_u8, [:register, :register]),
    "sw"    => IDef.new(0x2b.to_u8, [:register, :register]),
    "sh"    => IDef.new(0x2c.to_u8, [:register, :register]),
    "sb"    => IDef.new(0x2d.to_u8, [:register, :register]),
    "halt"  => IDef.new(0xff.to_u8, [] of Symbol),
  }

  def handle_instruction(instr : Instruction, program, labels)
    instr_def = INSTRUCTION_DEFS.fetch(instr.opcode_mnemonic) do
      raise "Unknown instruction name: #{instr.opcode_mnemonic}"
    end

    # Add opcode
    opcode = instr_def.opcode
    program << opcode

    # Validate args
    if instr.args.size != instr_def.args.size
      raise "Incorrect argument count (#{instr.inspect}; is #{instr.args.size}, expected #{instr_def.args.size}"
    end
    instr.args.each_with_index do |arg, i|
      arg_def = instr_def.args[i]
      unless arg_def == arg.kind
        raise "Incorrect argument type (#{instr.inspect}; is #{arg.class}, expected #{arg_def})"
      end
      unless arg.valid?
        raise "Invalid argument (#{instr.inspect}; #{arg.inspect})"
      end
    end

    # Add args
    instr.args.each do |arg|
      arg.bytes(labels).each { |b| program << b }
    end
  end
end

# Get filenames
if ARGV.size != 1
  STDERR.puts "usage: #{File.basename($0)} [filename]"
  exit 1
end
input_filename = ARGV[0]
output_filename =
  File.join(
    File.dirname(input_filename),
    File.basename(input_filename, ".rcs") + ".rcb")

# Read
raw_lines = File.read_lines(input_filename)

# Assemble
bytes = Assembler.new(raw_lines).assemble

# Write
File.open(output_filename, "w") do |io|
  bytes.each do |byte|
    io.write_byte(byte)
  end
end
