require "colorize"
require "log"

enum Log::Severity
  def short : Char
    case self
    when Trace
      'T'
    when Debug
      'D'
    when Info
      'I'
    when Notice
      'N'
    when Warn
      'W'
    when Error
      'E'
    when Fatal
      'F'
    when None
      'N'
    else
      to_s[0]
    end
  end
end

module Geode
  class NilLog < ::Log
    SILENCED = [] of String

    def initialize(source)
      super source, nil, Log::Severity::None
    end

    {% for method in ::Log::Severity.constants %}
      def self.{{ method.downcase }}(&block)
      end
      def self.{{ method.downcase }}
      end
    {% end %}
  end
end

class Log
  def self.for(source : String, level : Severity? = nil) : Log
    if Geode::NilLog::SILENCED.includes? source
      return Geode::NilLog.new source
    else
      previous_def
    end
  end

  macro disable_logging(mod)
    {% ::Geode::NilLog::SILENCED.push mod %}
  end

  def self.log(severity : Log::Severity, *, exception : Exception? = nil, &block)
    {% for sev in %i(Trace Debug Info Notice Warn Error Fatal) %}
      case severity
      when Log::Severity::{{ sev.id }}
        Top.{{ sev.id.downcase }}(exception: exception) do |dsl|
          yield dsl
        end
      end
    {% end %}
  end
end

class Log::Builder
  @format : Log::Formatter = SimpleFormat

  def format(@format : Log::Formatter)
  end

  def format_extended
    @format = ExtendedSimpleFormat
  end

  def stderr(severity = Severity::Debug, match = "*")
    self.bind(match, severity, Log::IOBackend.new(STDERR, dispatcher: :sync, formatter: @format))
  end

  def file(path, severity = Severity::Info, match = "*")
    self.bind(match, severity, Log::IOBackend.new(File.open(path), dispatcher: :sync, formatter: @format))
  end

  def custom(backend, severity = Severity::Debug, match = "*")
    self.bind(match, severity, backend)
  end
end

struct SimpleFormat < Log::StaticFormatter
  FMT = "%m/%d %H:%M:%S"

  def initialize(*args)
    super(*args)
    Colorize.on_tty_only!
  end

  def self.color(sev : Log::Severity)
    case sev
    when Log::Severity::Debug
      Colorize::ColorANSI::Blue
    when Log::Severity::Error, Log::Severity::Fatal
      Colorize::ColorANSI::Red
    when Log::Severity::Warn
      Colorize::ColorANSI::Yellow
    else
      Colorize::ColorANSI::Default
    end
  end

  def run
    s = @entry.severity
    Colorize.with.fore(SimpleFormat.color(s)).surround(@io) do |io|
      t = @entry.timestamp.to_s FMT
      @io << "[#{s.label[0]} #{t}] #{@entry.message}"
      if details = @entry.data[:details]?
        @io << "\n" << details
      end
      if ex = @entry.exception
        ex.inspect_with_backtrace @io
      end
    end
  end
end

struct ExtendedSimpleFormat < Log::StaticFormatter
  FMT = "%m/%d %H:%M:%S"

  def initialize(*args)
    super(*args)
    Colorize.on_tty_only!
  end

  def run
    s = @entry.severity
    Colorize.with.fore(SimpleFormat.color(s)).surround(@io) do |io|
      t = @entry.timestamp.to_s FMT
      @io << "[#{s.label[0]} #{t}] #{@entry.source}: #{@entry.message}"
      if details = @entry.data[:details]?
        @io << "\n" << details
      end
      if ex = @entry.exception
        @io << '\n'
        ex.inspect_with_backtrace @io
      end
    end
  end
end
