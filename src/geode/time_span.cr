struct Time::Span
  def to_s(io)
    if self.zero?
      io << "0s"
      return
    end
    io << '-' if @seconds < 0 || @nanoseconds < 0
    d = self.days.abs
    io << d << 'd' if d > 0
    h = self.hours.abs
    io << h << 'h' if h > 0
    m = self.minutes.abs
    io << m << 'm' if m > 0
    ts = self.total_seconds.abs
    return if ts > 600
    s = self.seconds.abs
    if s > 0 && ts < 10
      ms = self.milliseconds.abs // 100
      io << s << '.' << ms << 's'
    elsif ts < 1
      ms = self.milliseconds.abs
      if ms == 0
        us = self.microseconds.abs
        io << us << "us"
      elsif ms < 10
        us = self.microseconds.abs // 100
        io << ms << '.' << us << "ms"
      else
        io << ms << "ms"
      end
    elsif s > 0
      io << s << 's'
    end
  end

  def inspect(io : IO) : Nil
    if self.zero?
      io << "0s"
      return
    end
    io << '-' if @seconds < 0 || @nanoseconds < 0
    d = self.days.abs
    io << d << 'd' if d > 0
    h = self.hours.abs
    io << h << 'h' if h > 0
    m = self.minutes.abs
    io << m << 'm' if m > 0
    s = self.seconds.abs
    io << s << 's' if s > 0
    ms = self.milliseconds.abs
    io << ms << "ms" if ms > 0
    us = self.microseconds.abs
    io << us << "us" if us > 0
    ns = self.nanoseconds.abs
    io << ns << "ns" if ns > 0
  end
end
