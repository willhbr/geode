class Geode::Semaphore
  def initialize(limit : Int32)
    @chan = Channel(Nil).new limit
    limit.times do
      @chan.send nil
    end
  end

  def take
    @chan.receive
    begin
      yield
    ensure
      @chan.send nil
    end
  end
end
