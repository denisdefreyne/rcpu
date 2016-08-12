require "sdl2"

include SDL2

@[Link("SDL2_gfx")]
lib LibSDL2_GFX
  fun box_color = boxColor(dst : Void*, x1 : Int16, y1 : Int16, x2 : Int16, y2 : Int16, color : UInt32) : Int32
end

# ABGR
ON  = 0xFF005CFF_u32
OFF = 0xFF301E0E_u32

class Graphics
  property render

  def initialize(title : String, width : Int32, height : Int32)
    @render_changed = false

    # Create window
    @window = LibSDL2.create_window(
      title,
      LibSDL2::WINDOWPOS_CENTERED,
      LibSDL2::WINDOWPOS_CENTERED,
      width,
      height,
      Window::Flags::SHOWN)
    unless @window
      raise "SDL_CreateWindow Error: #{SDL2.error}"
    end

    # Create renderer
    @render = LibSDL2.create_renderer(
      @window,
      -1,
      Renderer::Flags::ACCELERATED | Renderer::Flags::PRESENTVSYNC | Renderer::Flags::TARGETTEXTURE)
    unless @render
      raise "SDL_CreateRenderer Error: #{SDL2.error}"
    end

    LibSDL2.set_render_draw_blend_mode(@render, LibSDL2::BlendMode::BLEND)

    # Create texture
    @texture = LibSDL2.create_texture(
      @render,
      0x16462004_u32,
      LibSDL2::TextureAccess::TARGET,
      width,
      height)

    LibSDL2.set_render_target(@render, @texture)
  end

  def update_render
    if @render_changed
      LibSDL2.set_render_target(@render, nil)
      LibSDL2.render_copy(@render, @texture, nil, nil)
      LibSDL2.render_present(@render)
      @render_changed = false
    end
  end

  def set_render_changed
    @render_changed = true
  end

  def clear_background
    LibSDL2.set_render_draw_color(
      @render,
      (OFF & 0x000000ff) >> 0,
      (OFF & 0x0000ff00) >> 8,
      (OFF & 0x00ff0000) >> 16,
      (OFF & 0xff000000) >> 24,
    )
    LibSDL2.render_clear(@render)
  end

  def draw_block(x, y, width, height, color)
    LibSDL2_GFX.box_color(@render as Void*, x.to_i16, y.to_i16, x.to_i16 + width, y.to_i16 + width, color)

    set_render_changed
  end

  def render
    LibSDL2.set_render_target(@render, @texture)
    clear_background
    yield
    update_render
  end

  def finalize
    LibSDL2.destroy_renderer(@render)
    LibSDL2.destroy_window(@window)
  end
end

EMPTY  = 0xFF4f4c42_u32
TEAL   = 0xFFFFDB7F_u32
BLUE   = 0xFFD97400_u32
ORANGE = 0xFF1B85FF_u32
YELLOW = 0xFF00DCFF_u32
GREEN  = 0xFF40CC2E_u32
PURPLE = 0xFF4B1485_u32
RED    = 0xFF4B59F2_u32

class Video
  PADDING = 16

  def initialize(mem : Mem)
    @mem = mem
  end

  def draw_once(graphics)
    row_length_in_bytes = 160
    num_rows = 120

    num_bytes = num_rows * row_length_in_bytes

    num_bytes.times do |index|
      x = (index % row_length_in_bytes)
      y = (index / row_length_in_bytes)

      byte = @mem.fetch(0x10000 + index)
      color = (byte != 0x00) ? ON : OFF
      graphics.draw_block(PADDING + x * 4, PADDING + y * 4, 4, 4, color)
    end
  end

  def draw
    SDL2.run(SDL2::INIT::EVERYTHING) do
      graphics = Graphics.new("RCPU 3000", 2 * PADDING + 640, 2 * PADDING + 480)

      yield(graphics)
    end
  end

  def update(graphics)
    graphics.render do
      draw_once(graphics)
    end
  end

  def get_input
    while LibSDL2.poll_event(out e) == 1
      case e.type
      when EventType::QUIT
        return :quit
      end
    end
    return :none
  end

  def run(cpu, num_cycles)
    draw do |g|
      loop do
        case get_input
        when :quit
          break
        end

        cpu.run(num_cycles)
        update(g)
        break unless cpu.running
      end
    end
  end
end
