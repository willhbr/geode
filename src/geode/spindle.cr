class Fiber
  class CancellationException < Exception
  end

  @cancelled : Bool = false

  def cancel
    @cancelled = true
  end

  def self.check_cancelled!
    if Fiber.current.@cancelled
      raise CancellationException.new "Fiber cancelled"
    end
  end

  def self.cancelled?
    Fiber.current.@cancelled
  end
end

class Geode::Spindle
  @lock = Mutex.new
  @completion = Channel(Bool).new(1)
  @child_count = 0
  @children = Array(Fiber).new
  @failures = Array(Exception).new
  @cancelled = false

  def self.run
    spindle = new
    spindle.wrapped_internal(true) do
      yield spindle
    end
    spindle.join
  end

  private def initialize
  end

  def spawn(&block)
    @lock.synchronize do
      if @completion.closed?
        raise "cannot spawn on a closed spindle"
      end
      @child_count += 1
      ::spawn do
        self.wrapped_internal(false) do
          block.call
        end
      end
    end
  end

  def wrapped(&block)
    wrapped_internal(true) do
      yield
    end
  end

  protected def wrapped_internal(count_child, &block)
    begin
      self.mark_started(Fiber.current, count_child: count_child)
      yield
    rescue cancelled : Fiber::CancellationException
      self.cancel
    rescue ex : Exception
      self.mark_failed ex
    ensure
      self.mark_completion
    end
  end

  def join
    @completion.receive
    @completion.close
    @lock.synchronize do
      if f = @failures.first?
        raise f
      end
      Fiber.check_cancelled!
    end
  end

  def to_s(io : IO)
    io << "#<" << {{ @type }} << ":0x"
    object_id.to_s(io, 16)
    io << ' ' << (@completion.closed? ? "closed" : "open")
    io << " fibers: " << @child_count << '>'
  end

  def inspect(io : IO)
    to_s io
  end

  def cancel
    @lock.synchronize do
      return if @cancelled
      @cancelled = true
      @children.each &.cancel
    end
  end

  def child_count : Int32
    @lock.synchronize do
      return @child_count
    end
  end

  protected def mark_failed(ex : Exception)
    @lock.synchronize do
      @failures << ex
    end
  end

  protected def mark_started(fib : Fiber, count_child = false)
    @lock.synchronize do
      @child_count += 1 if count_child
      @children << fib
      if fib.@cancelled || @cancelled
        fib.cancel if fib != Fiber.current
        raise Fiber::CancellationException.new "Fiber cancelled"
      end
    end
  end

  protected def mark_completion
    @lock.synchronize do
      count = @child_count -= 1
      if count <= 0
        @completion.send true
      end
    end
  end
end
