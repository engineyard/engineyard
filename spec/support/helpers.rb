module Kernel
  def capture_stdio(input = nil, &block)
    require 'stringio'
    org_stdin, $stdin = $stdin, StringIO.new(input) if input
    org_stdout, $stdout = $stdout, StringIO.new
    yield
    return @out = $stdout.string
  ensure
    $stdout = org_stdout
    $stdin = org_stdin
  end
  alias capture_stdout capture_stdio
end

class IO
  def read_available_bytes(chunk_size = 1024, select_timeout = 5)
    buffer = []

    while self.class.select([self], nil, nil, select_timeout)
      begin
        buffer << self.readpartial(chunk_size)
      rescue(EOFError)
        break
      end
    end

    return buffer.join
  end
end

def ey(cmd = nil, options = {})
  require "open3"
  hide_err = options.delete(:hide_err)

  args = options.map { |k,v| "--#{k} #{v}"}.join(" ")
  eybin = File.expand_path('../bundled_ey', __FILE__)

  @in, @out, @err = Open3.popen3("#{eybin} #{cmd} #{args}")

  yield @in if block_given?
  @err = @err.read_available_bytes
  @out = @out.read_available_bytes

  puts @err unless @err.empty? || hide_err
  @out
end
