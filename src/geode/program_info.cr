module Geode::ProgramInfo
  BUILT_AT   = Time.unix({{ `date +%s`.strip + "_i64" }})
  STARTED_AT = Time.utc

  def self.print(io = STDOUT)
    to_s(io)
  end

  def self.log(sev = Log::Severity::Info)
    Log.log(sev) { String.build { |io| to_s(io) } }
  end

  def self.to_s(io : IO)
    if PROGRAM_NAME != Process.executable_path
      io.puts "#{Process.executable_path} \\ # (#{PROGRAM_NAME})"
    else
      io.puts "#{PROGRAM_NAME} \\"
    end
    io.puts ARGV.map { |arg| "  #{arg}" }.join(" \\\n")
    io.puts "\n  Built at #{BUILT_AT} (Crystal #{Crystal::VERSION})"
    io.puts "  Started at #{STARTED_AT}"
  end
end
