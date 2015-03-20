class Reg
  def initialize
    @reg = {
      0_u8  => 0_u32,      # r0
      1_u8  => 0_u32,      # r1
      2_u8  => 0_u32,      # r2
      3_u8  => 0_u32,      # r3
      4_u8  => 0_u32,      # r4
      5_u8  => 0_u32,      # r5
      6_u8  => 0_u32,      # r6
      7_u8  => 0_u32,      # r7
      8_u8  => 0_u32,      # rpc
      9_u8  => 0_u32,      # rflags
      10_u8 => 0xffff_u32, # rsp
      11_u8 => 0_u32,      # rbp
      12_u8 => 0_u32,      # rr
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
