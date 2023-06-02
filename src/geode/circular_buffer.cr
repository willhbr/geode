class Geode::CircularBuffer(T)
  include Enumerable(T)
  getter? full : Bool

  @buffer : Slice(T)

  def initialize(capacity)
    @buffer = Slice(T).new(
      capacity,
      value: default_val)
    @idx = 0
    @full = false
  end

  @[AlwaysInline]
  private def default_val : T
    {% if T < Int || T < Float %}
      {{ T }}.new(0)
    {% else %}
      T.allocate
    {% end %}
  end

  def <<(value : T)
    push value
    self
  end

  def push(value : T)
    @buffer[@idx] = value
    @idx += 1
    if @idx >= self.capacity
      @idx = 0
      @full = true
    end
  end

  def clear
    @idx = 0
    @full = false
  end

  def capacity
    @buffer.size
  end

  def size
    @full ? self.capacity : @idx
  end

  def empty?
    !@full && @idx.zero?
  end

  def each
    cap = self.capacity
    range = @full ? @idx...(@idx + cap) : 0...@idx
    range.each do |idx|
      yield @buffer[idx % cap]
    end
  end

  def each_last(count)
    cap = self.capacity
    count = {cap, count}.min
    if @full
      finish = @idx + cap
      start = finish - count
    else
      finish = @idx
      start = {finish - count, 0}.max
    end
    (start...finish).each do |idx|
      yield @buffer[idx % cap]
    end
  end

  def to_s(io)
    io << '['
    first = true
    each do |item|
      io << ", " unless first
      item.to_s(io)
      first = false
    end
    io << ']'
  end
end
