class Geode::Spindle
  @lock = Mutex.new
  @completion = Channel(Bool).new(1)
  @child_count = 0
  @super_spindle : Spindle? = nil

  def spawn(&block)
    @lock.synchronize do
      if @completion.closed?
        raise "cannot spawn on a closed spindle"
      end
      @child_count += 1
      ::spawn do
        begin
          block.call
        ensure
          self.mark_completion
        end
      end
    end
  end

  def child : Spindle
    @lock.synchronize do
      s = Spindle.new
      s.set_super(self)
      @child_count += 1
      return s
    end
  end

  def join
    @completion.receive
    @completion.close
    if s = @super_spindle
      s.mark_completion
    end
  end

  def finalize
    if @child_count > 0
      raise "Spindle finalized with unjoined fibers"
    end
  end

  def to_s(io : IO)
    io << "#<" << {{ @type }} << ":0x"
    object_id.to_s(io, 16)
    io << ' ' << (@completion.closed? ? "closed" : "open")
    if s = @super_spindle
      io << " parent: "
      s.to_s(io)
    end
    io << " fibers: " << @child_count << '>'
  end

  def inspect(io : IO)
    to_s io
  end

  protected def set_super(@super_spindle)
  end

  protected def mark_completion
    @lock.synchronize do
      c = @child_count -= 1
      if c <= 0
        @completion.send true
      end
    end
  end
end
