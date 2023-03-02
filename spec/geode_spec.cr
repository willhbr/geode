require "./spec_helper"

describe Geode::LineReader do
  it "reads some lines" do
    lines = Array(String).new
    lr = Geode::CallbackLineReader.new do |line|
      lines << line
    end
    lr.print "foo"
    lr.puts "bar"
    lr.puts "second\nthird"
    lines.should eq(%w(foobar second third))
  end

  it "builds multiple buffers" do
    lines = Array(String).new
    lr = Geode::CallbackLineReader.new do |line|
      lines << line
    end
    lr.print "foo"
    lr.print "bar"
    lr.puts "baz"
    lines.should eq(%w(foobarbaz))
  end
end

describe Geode::Spindle do
  it "spawns and waits" do
    s = Spindle.new
    res = [] of Int32
    s.spawn do
      sleep 50.milliseconds
      res << 1
    end
    s.spawn do
      sleep 20.milliseconds
      res << 2
    end
    s.join
    res.should eq([2, 1])
  end

  it "handles sub spindles" do
    s = Spindle.new
    res = [] of Int32
    sub = s.child
    sub.spawn do
      sleep 10.milliseconds
      res << 1
    end
    sub.spawn do
      sleep 20.milliseconds
      res << 2
    end
    sub.join
    res << 3
    s.join
    res.should eq([1, 2, 3])
  end
end
