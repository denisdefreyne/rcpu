class Mem
  def initialize
    @wrapped = {} of UInt32 => UInt8
  end

  def [](address)
    fetch(address)
  end

  def fetch(address)
    @wrapped.fetch(address)
  end

  def []=(address, value)
    @wrapped[address] = value
  end
end
