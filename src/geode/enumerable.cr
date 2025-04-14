require "./semaphore"
require "./spindle"

module Enumerable(T)
  def each_parallel(limit : Int32, &block : Proc(T, Nil))
    s = Geode::Semaphore.new limit
    Geode::Spindle.run do |sp|
      each do |item|
        sp.spawn do
          s.take do
            block.call item
          end
        end
      end
    end
  end
end
