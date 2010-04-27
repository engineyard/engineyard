require 'realweb'
require "rest_client"

module Spec
  module Helpers
    def ey(cmd = nil, options = {})
      require "open3"
      hide_err = options.delete(:hide_err)
      ENV['DEBUG'] = options.delete(:debug).to_s

      args = options.map { |k,v| "--#{k} #{v}"}.join(" ")
      eybin = File.expand_path('../bundled_ey', __FILE__)

      @in, @out, @err = Open3.popen3("#{eybin} #{cmd} #{args}")

      yield @in if block_given?
      @err = @err.read_available_bytes
      @out = @out.read_available_bytes
      @ssh_commands = @out.split(/\n/).find_all do |line|
        line =~ /^ssh/
      end.map do |line|
        line.sub(/^.*?\"/, '').sub(/\"$/, '')
      end

      puts @err unless @err.empty? || hide_err
      @out
    end

    def api_scenario(scenario)
      response = ::RestClient.put(EY.fake_awsm + '/scenario', {"scenario" => scenario}, {})
      raise "Setting scenario failed: #{response.inspect}" unless response.code == 200
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
        unless system("ruby -c spec/support/fake_awsm.ru > /dev/null")
          raise SyntaxError, "There is a syntax error in fake_awsm.ru! fix it!"
        end
        config_ru = File.join(EY_ROOT, "spec/support/fake_awsm.ru")
        @server = RealWeb.start_server(config_ru)
        "http://localhost:#{@server.port}"
      end
    end
    alias_method :start_fake_awsm, :fake_awsm
  end
end
