require 'stringio'

module Kernel
  def capture_stdout(&block)
    org_stdout, $stdout = $stdout, StringIO.new
    yield
    return $stdout.string
  ensure
    $stdout = org_stdout
  end

  def capture_stderr(&block)
    org_stderr, $stderr = $stderr, StringIO.new
    yield
    return $stderr.string
  ensure
    $stderr = org_stderr
  end

  def capture_stdio(&block)
    stderr, stdout = "", ""
    stderr = capture_stderr do
      stdout = capture_stdout(&block)
    end
    return [stdout, stderr]
  end
end

def ey(cmd = nil, options = {})
  require "open3"
  silence_err = options.delete(:err)

  args = options.map { |k,v| "--#{k} #{v}"}.join(" ")
  eybin = File.expand_path('../bundled_ey', __FILE__)

  @in, @out, @err = Open3.popen3("#{eybin} #{cmd} #{args}")
  @err = @err.read.strip
  puts @err unless @err.empty? || silence_err
  @out = @out.read.strip
end
