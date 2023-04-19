require "yaml"
require "./time_span"

struct Time::Span
  def self.from_string(string)
    got_value = false
    value : UInt32 = 0
    decimal : Float64 = 0
    span_seconds : Int64 = 0
    span_nanos : Int32 = 0
    prev_char = '\0'
    decimal_pt = 0
    string.each_char do |char|
      if char.ascii_number?
        if prev_char == 'm'
          span_seconds += value * 60
          value = 0
        end
        if decimal_pt.zero?
          value = value * 10 + char.to_i
        else
          decimal_pt *= 10
          decimal += char.to_i / decimal_pt
        end
        prev_char = '\0'
      else
        case char
        when '.'
          decimal_pt = 1
          next
        when 'd'
          span_seconds += (value * 24 * 60 * 60) + (decimal * 24 * 60 * 60).to_u32
          value = 0
        when 'h'
          span_seconds += (value * 60 * 60) + (decimal * 60 * 60).to_u32
          value = 0
        when 'm'
          # Do nothing, this may be millis or minutes
        when 's'
          case prev_char
          when 'm'
            span_nanos += (value * 1000000) + (decimal * 1000000).to_u32
            value = 0
          when 'μ', 'u'
            span_nanos += (value * 1000) + (decimal * 1000).to_u32
            value = 0
          when 'n'
            span_nanos += value
            span_nanos += value + decimal.to_u32
            value = 0
          when '\0'
            span_seconds += value
          else
            raise "Invalid char: #{char}"
          end
        when ' ', '\t'
        else
          raise "Invalid char: #{char}"
        end
        prev_char = char
        decimal_pt = 0
      end
    end
    if prev_char == 'm'
      span_seconds += value * 60
    end
    new(seconds: span_seconds, nanoseconds: span_nanos)
  end

  def to_json(builder)
    builder.scalar(self.to_s)
  end

  def self.new(pull : JSON::PullParser)
    return from_string(pull.read_string)
  end

  def self.new(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
    ctx.read_alias(node, String) do |obj|
      return from_string(obj)
    end

    if node.is_a?(YAML::Nodes::Scalar)
      value = node.value
      ctx.record_anchor(node, value)
      from_string value
    else
      node.raise "Expected String for Time::Span, not #{node.class.name}"
    end
  end
end
