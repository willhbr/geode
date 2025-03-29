module Enumerable(T)
  def each_parallel(count : Int32, &block : Proc(T, Nil))
    chan = Channel(Nil).new(count)
    count.times { chan.send nil }
    fin = Channel(Nil).new
    each_with_index do |item, index|
      spawn do
        chan.receive
        block.call item
        chan.send nil
        fin.send nil if index == size - 1
      end
    end
    fin.receive
  end
end
