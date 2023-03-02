require "./spindle"

class Geode::WorkerPool(T)
  private def initialize(@spindle : Spindle, @parallel : Int32, &@block : Proc(T, Nil))
    @queue = Channel(T).new
  end

  def start
    @parallel.times do
      @spindle.spawn do
        while item = @queue.receive?
          @block.call(item)
        end
      end
    end
  end

  def add(item : T)
    @queue.send item
  end

  def add(items : Array(T))
    items.each { |t| @queue.send(t) }
  end

  def add(*items : T)
    items.each { |t| @queue.send(t) }
  end

  def stop
    @queue.close
  end

  def self.create(spindle : Spindle, parallel : Int32 = 4, &block : Proc(T, Nil)) : WorkerPool(T)
    pool = new(spindle, parallel, &block)
    pool.start
    return pool
  end

  def self.process(items : Enumerable(T), parallel : Int32 = 4, &block : Proc(T, Nil))
    spindle = Spindle.new
    pool = create(spindle, parallel, &block)
    pool.add(items)
    pool.stop
    spindle.join
  end
end
