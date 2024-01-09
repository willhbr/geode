abstract class Geode::LineReader < IO
  @buffer = IO::Memory.new
  getter bytes_read : Int32 = 0

  abstract def written(line : String)

  def write(slice : Bytes) : Nil
    @bytes_read += slice.size
    prev_idx = 0
    while idx = slice.index('\n'.ord, offset: prev_idx)
      line = String.build do |io|
        unless @buffer.empty?
          @buffer.rewind
          IO.copy @buffer, io
          @buffer.clear
        end
        io.write slice[prev_idx...idx]
      end
      written line
      prev_idx = idx + 1
    end

    @buffer.write slice[prev_idx..-1]
  end

  def read(slice : Bytes) : Int32
    return 0
  end

  def close
    unless @buffer.empty?
      @buffer.rewind
      written @buffer.to_s
    end
    @buffer.close
  end
end

class Geode::CallbackLineReader < Geode::LineReader
  def initialize(&@block : (String) ->)
  end

  def written(line : String)
    @block.call(line)
  end
end
