class Reg
  R0     = 0_u8
  R1     = 1_u8
  R2     = 2_u8
  R3     = 3_u8
  R4     = 4_u8
  R5     = 5_u8
  R6     = 6_u8
  R7     = 7_u8
  RPC    = 8_u8
  RFLAGS = 9_u8
  RSP    = 10_u8
  RBP    = 11_u8
  RR     = 12_u8

  def initialize
    @reg = {
      R0     => 0_u32,
      R1     => 0_u32,
      R2     => 0_u32,
      R3     => 0_u32,
      R4     => 0_u32,
      R5     => 0_u32,
      R6     => 0_u32,
      R7     => 0_u32,
      RPC    => 0_u32,
      RFLAGS => 0_u32,
      RSP    => 0xffff_u32,
      RBP    => 0_u32,
      RR     => 0_u32,
    }
  end

  def [](num)
    @reg.fetch(num)
  end

  def []=(num, value)
    unless @reg.has_key?(num)
      raise "Unknown register: #{num}"
    end

    @reg[num] = value
  end

  def each
    @reg.each { |r| yield(r) }
  end
end
