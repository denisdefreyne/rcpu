require "sdl2"
require "option_parser"

require "./cpu"
require "./mem"
require "./reg"
require "./video"

enble_video = false

op = OptionParser.parse! do |opts|
  opts.banner = "Usage: rcpu-emulate [options] filename"
  opts.on("-V", "--video", "enable video") do
    enble_video = true
  end
  opts.on("-h", "--help", "print this help menu") do
    puts opts
    exit 0
  end
end

if ARGV.size != 1
  puts op
  exit 1
end

# Read instructions into memory
filename = ARGV.first
bytes = [] of UInt8
File.open(filename, "r") do |io|
  loop do
    byte = io.read_byte
    if byte
      bytes << byte
    else
      break
    end
  end
end
mem = Mem.new
bytes.each_with_index do |byte, index|
  mem[index.to_u32] = byte
end

# Set video memory
160.times do |x|
  120.times do |y|
    index = 0x10000 + (x * 120 + y)
    mem[index.to_u32] = 0_u8
  end
end

# Run
cpu = CPU.new(mem)
if enble_video
  video = Video.new(mem)
  video.run(cpu, 40)
else
  cpu.run
end
