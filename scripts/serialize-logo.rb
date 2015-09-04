require 'chunky_png'

image = ChunkyPNG::Image.from_file('/Users/ddfreyne/Desktop/soundcloud-logo-bw.png')
puts image.pixels.map { |pixel| pixel <= 255 ? 0 : 1 }.map { |i| ".byte 0x0#{i}" }.join("\n")
