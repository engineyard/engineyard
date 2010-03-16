require 'stringio'

module Kernel
  def capture_stdio(input = nil, &block)
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

def ey(cmd = nil, options = {})
  require "open3"
  silence_err = options.delete(:hide_err)

  args = options.map { |k,v| "--#{k} #{v}"}.join(" ")
  eybin = File.expand_path('../bundled_ey', __FILE__)

  @in, @out, @err = Open3.popen3("#{eybin} #{cmd} #{args}")
  @err = @err.read.strip
  puts @err unless @err.empty? || silence_err
  @out = @out.read.strip
end
