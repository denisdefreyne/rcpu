require 'chunky_png'

if ARGV.size != 1
  $stderr.puts "usage: #{$0} [filename]"
  exit 1
end
filename = ARGV[0]

image = ChunkyPNG::Image.from_file(filename)
puts image.pixels.map { |pixel| pixel <= 255 ? 0 : 1 }.map { |i| ".byte 0x0#{i}" }.join("\n")
