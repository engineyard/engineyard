require 'realweb'

module Spec
  module Helpers
    def ey(cmd = nil, options = {})
      require "open3"
      hide_err = options.delete(:hide_err)
      ENV['DEBUG'] = options.delete(:debug)

      args = options.map { |k,v| "--#{k} #{v}"}.join(" ")
      eybin = File.expand_path('../bundled_ey', __FILE__)

      @in, @out, @err = Open3.popen3("#{eybin} #{cmd} #{args}")

      yield @in if block_given?
      @err = @err.read_available_bytes
      @out = @out.read_available_bytes

      puts @err unless @err.empty? || hide_err
      @out
    end

    def read_yaml(file="ey.yml")
      YAML.load_file(File.expand_path(file))
    end

    def write_yaml(data, file = "ey.yml")
      File.open(file, "w"){|f| YAML.dump(data, f) }
    end
  end
end

module EY
  class << self
    def fake_awsm
      @fake_awsm ||= begin
        config_ru = File.join(EY_ROOT, "spec/support/fake_awsm.ru")
        @server = RealWeb.start_server(config_ru)
        "http://localhost:#{@server.port}"
      end
    end
    alias_method :start_fake_awsm, :fake_awsm
  end
end