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

class Token
  property kind

  def initialize
    @kind = :unknown
    @content_io = StringIO.new
  end

  def empty
    @content_io = StringIO.new
  end

  def append_char(c)
    @content_io << c
  end

  def content
    @content_io.to_s
  end

  def inspect(io)
    io << kind.to_s.upcase

    if content.size > 0
      io << "(#{content})"
    end
  end
end

class Lexer
  getter tokens

  def initialize(@input)
    @index = 0
    @tokens = [] of Token
    @current_token = Token.new
  end

  def run
    until @index >= @input.size
      char = @input[@index]
      @index += 1

      case char
      when '@'
        @current_token.kind = :at
        @current_token.empty
        finish_token
      when '.'
        @current_token.kind = :dot
        @current_token.empty
        finish_token
      when ':'
        @current_token.kind = :colon
        @current_token.empty
        finish_token
      when ','
        @current_token.kind = :comma
        @current_token.empty
        finish_token
      when ' ', '\t'
        @current_token.kind = :space
        @current_token.append_char(char)
        consume_space
        finish_token
      when '\n'
        @current_token.kind = :newline
        @current_token.empty
        finish_token
      when '#'
        @current_token.kind = :comment
        @current_token.append_char(char)
        consume_until_newline
        finish_token
      when '0' .. '9'
        @current_token.kind = :number
        unread_char # input required for decision making
        consume_number
        finish_token
      when 'a' .. 'z', 'A' .. 'Z'
        @current_token.kind = :identifier
        @current_token.append_char(char)
        consume_identifier
        finish_token
      else
        raise "lexer error before #{char} at #{@index}"
      end
    end

    if @current_token.content.size > 0
      puts "Warning: unfinished token after end of lexing"
      finish_token
    end
    @current_token.kind = :eof
    finish_token
  end

  def unread_char
    @index -= 1
  end

  def finish_token
    @tokens << @current_token
    @current_token = Token.new
  end

  def consume_until_newline
    until @index >= @input.size
      char = @input[@index]
      @index += 1

      case char
      when '\n'
        unread_char
        return
      else
        @current_token.append_char(char)
      end
    end
  end

  def consume_space
    until @index >= @input.size
      char = @input[@index]
      @index += 1

      case char
      when ' ', '\t'
        @current_token.append_char(char)
      else
        unread_char
        return
      end
    end
  end

  def consume_identifier
    until @index >= @input.size
      char = @input[@index]
      @index += 1

      case char
      when 'a' .. 'z', 'A' .. 'Z', '0' .. '9', '-', '_'
        @current_token.append_char(char)
      else
        unread_char
        return
      end
    end
  end

  def consume_number
    state = :pre

    until @index >= @input.size
      char = @input[@index]
      @index += 1

      case state
      when :pre
        case char
        when '0'
          @current_token.append_char(char)
          state = :zero
        when '1' .. '9'
          @current_token.append_char(char)
          state = :body
        else
          raise "consume_number: inconsistent lexer state"
        end
      when :zero
        case char
        when 'x', 'b'
          @current_token.append_char(char)
          state = :body
        when '0' .. '9'
          raise "consume_number: lexer error before #{char} at #{@index}"
        else
          unread_char
          return
        end
      when :body
        case char
          # TODO: be more strict
        when '0' .. '9', 'a' .. 'f', 'A' .. 'F'
          @current_token.append_char(char)
        else
          unread_char
          return
        end
      else
        raise "consume_number: inconsistent lexer state"
      end
    end
  end
end

class Parser
  getter statements

  def initialize(@input)
    @index = 0
    @statements = [] of Instruction | Label | DataDirective
  end

  def run
    loop do
      case current_token.kind
      when :comment
        advance
      when :identifier # label
        consume_label
      when :space # instruction
        consume_instruction
      when :newline # empty line
        advance
      when :dot # data directive
        consume_data_directive
      when :eof
        break
      else
        raise "Parser: unexpected #{current_token.kind.to_s.upcase}"
      end
    end
  end

  def consume_data_directive
    advance # dot

    directive_kind = consume(:identifier).content
    length =
      case directive_kind
      when "byte"
        1
      when "half"
        2
      when "word"
        4
      else
        raise "Parser: invalid data directive kind: #{directive_kind}"
      end

    consume(:space)

    arg =
      case current_token.kind
      when :number
        number_token = consume
        ImmArg.new(parse_int(number_token.content))
      when :at
        advance
        label_name = consume(:identifier).content
        LabelArg.new(label_name)
      else
        raise "Parser: unexpected #{current_token.kind.to_s.upcase}"
      end

    case current_token
    when :newline
      advance
    when :space
      advance
      consume(:comment)
      consume(:newline)
    end

    @statements << DataDirective.new(length, arg)
  end

  def consume_label
    name = consume(:identifier)
    consume(:colon)

    case current_token
    when :newline
      advance
    when :space
      advance
      consume(:comment)
      consume(:newline)
    end

    @statements << Label.new(name.content)
  end

  def consume_instruction
    advance

    if current_token.kind == :comment
      advance
      consume(:newline)
      return
    end

    opcode_mnemonic = consume(:identifier).content
    case current_token.kind
    when :newline
      advance
      @statements << Instruction.new(opcode_mnemonic, [] of Arg)
    when :space
      advance

      if current_token == :comment
        advance
        consume(:newline)
        return
      end

      args = [] of ImmArg | LabelArg | RegArg
      loop do
        args << consume_argument
        case current_token.kind
        when :newline
          advance
          break
        when :space
          advance
          maybe_consume(:comment)
          consume(:newline)
          break
        when :comma
          advance
          consume(:space)
        end
      end
      @statements << Instruction.new(opcode_mnemonic, args)
    else
      raise "Parser: unexpected #{current_token.kind.to_s.upcase}"
    end
  end

  def parse_int(content)
    case content
    when /\A0x/
      content[2..-1].to_i(16)
    when /\A0b/
      content[2..-1].to_i(2)
    else
      content.to_i
    end
  end

  def consume_argument
    case current_token.kind
    when :number # e.g. 0x123
      number_token = consume
      ImmArg.new(parse_int(number_token.content))
    when :at # e.g. @foo
      advance
      name = consume(:identifier)
      LabelArg.new(name.content)
    when :identifier # e.g. r0
      name = consume(:identifier)
      RegArg.new(name.content)
    else
      raise "Parser: unexpected #{current_token.kind.to_s.upcase}"
    end
  end

  def advance
    @index += 1
  end

  def unread_token
    @index -= 1
  end

  def current_token
    @input[@index]
  end

  def consume
    @input[@index].tap { advance }
  end

  def consume(kind)
    token = @input[@index]
    if token.kind == kind
      consume
    else
      raise "Parser: unexpected #{token.kind.to_s.upcase}"
    end
  end

  def maybe_consume(kind)
    token = @input[@index]
    if token.kind == kind
      @index += 1
    end
  end
end

################################################################################

class Assembler
  def initialize(@input)
  end

  def assemble
    lexer = Lexer.new(@input)
    lexer.run

    parser = Parser.new(lexer.tokens)
    parser.run

    statements = parser.statements
    labels = collect_labels(statements)
    generate_program(statements, labels)
  end

  private def collect_labels(statements)
    labels = {} of String => UInt32
    program = [] of UInt8
    statements.each do |statement|
      case statement
      when Instruction
        handle_instruction(statement, program, nil)
      when Label
        labels[statement.name] = program.size.to_u32
      when DataDirective
        statement.length.times { program << 0x00.to_u8 }
      end
    end
    labels
  end

  private def generate_program(statements, labels)
    program = [] of UInt8
    statements.each do |statement|
      case statement
      when Instruction
        handle_instruction(statement, program, labels)
      when DataDirective
        statement.bytes(labels).each { |byte| program << byte }
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
    # Function handling
    "call"  => IDef.new(0x01.to_u8, [:register]),
    "calli" => IDef.new(0x02.to_u8, [:immediate]),
    "ret"   => IDef.new(0x03.to_u8, [] of Symbol),
    # Stack management
    "push"  => IDef.new(0x04.to_u8, [:register]),
    "pushi" => IDef.new(0x05.to_u8, [:immediate]),
    "pop"   => IDef.new(0x06.to_u8, [:register]),
    # Branching
    "j"     => IDef.new(0x07.to_u8, [:register]),
    "ji"    => IDef.new(0x08.to_u8, [:immediate]),
    "je"    => IDef.new(0x09.to_u8, [:register]),
    "jei"   => IDef.new(0x0a.to_u8, [:immediate]),
    "jne"   => IDef.new(0x0b.to_u8, [:register]),
    "jnei"  => IDef.new(0x0c.to_u8, [:immediate]),
    "jg"    => IDef.new(0x0d.to_u8, [:register]),
    "jgi"   => IDef.new(0x0e.to_u8, [:immediate]),
    "jge"   => IDef.new(0x0f.to_u8, [:register]),
    "jgei"  => IDef.new(0x10.to_u8, [:immediate]),
    "jl"    => IDef.new(0x11.to_u8, [:register]),
    "jli"   => IDef.new(0x12.to_u8, [:immediate]),
    "jle"   => IDef.new(0x13.to_u8, [:register]),
    "jlei"  => IDef.new(0x14.to_u8, [:immediate]),
    # Arithmetic
    "cmp"   => IDef.new(0x15.to_u8, [:register, :register]),
    "cmpi"  => IDef.new(0x16.to_u8, [:register, :immediate]),
    "mod"   => IDef.new(0x17.to_u8, [:register, :register, :register]),
    "modi"  => IDef.new(0x18.to_u8, [:register, :register, :immediate]),
    "add"   => IDef.new(0x19.to_u8, [:register, :register, :register]),
    "addi"  => IDef.new(0x1a.to_u8, [:register, :register, :immediate]),
    "sub"   => IDef.new(0x1b.to_u8, [:register, :register, :register]),
    "subi"  => IDef.new(0x1c.to_u8, [:register, :register, :immediate]),
    "mul"   => IDef.new(0x1d.to_u8, [:register, :register, :register]),
    "muli"  => IDef.new(0x1e.to_u8, [:register, :register, :immediate]),
    "div"   => IDef.new(0x1f.to_u8, [:register, :register, :register]),
    "divi"  => IDef.new(0x20.to_u8, [:register, :register, :immediate]),
    "xor"   => IDef.new(0x21.to_u8, [:register, :register, :register]),
    "xori"  => IDef.new(0x22.to_u8, [:register, :register, :immediate]),
    "or"    => IDef.new(0x23.to_u8, [:register, :register, :register]),
    "ori"   => IDef.new(0x24.to_u8, [:register, :register, :immediate]),
    "and"   => IDef.new(0x25.to_u8, [:register, :register, :register]),
    "andi"  => IDef.new(0x26.to_u8, [:register, :register, :immediate]),
    "shl"   => IDef.new(0x27.to_u8, [:register, :register, :register]),
    "shli"  => IDef.new(0x28.to_u8, [:register, :register, :immediate]),
    "shr"   => IDef.new(0x29.to_u8, [:register, :register, :register]),
    "shri"  => IDef.new(0x2a.to_u8, [:register, :register, :immediate]),
    "not"   => IDef.new(0x2b.to_u8, [:register, :register]),
    # Register handling
    "mov"   => IDef.new(0x2c.to_u8, [:register, :register]),
    "li"    => IDef.new(0x2d.to_u8, [:register, :immediate]),
    # Memory handling
    "lw"    => IDef.new(0x2e.to_u8, [:register, :register]),
    "lh"    => IDef.new(0x2f.to_u8, [:register, :register]),
    "lb"    => IDef.new(0x30.to_u8, [:register, :register]),
    "sw"    => IDef.new(0x31.to_u8, [:register, :register]),
    "sh"    => IDef.new(0x32.to_u8, [:register, :register]),
    "sb"    => IDef.new(0x33.to_u8, [:register, :register]),
    # Special
    "prn"   => IDef.new(0xfe.to_u8, [:register]),
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
data = File.read(input_filename)

# Assemble
bytes = Assembler.new(data).assemble

# Write
File.open(output_filename, "w") do |io|
  bytes.each do |byte|
    io.write_byte(byte)
  end
end
