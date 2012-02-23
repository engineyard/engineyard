module EY
  class << self
    def fake_awsm
      @fake_awsm ||= load_fake_awsm
    end
    alias_method :start_fake_awsm, :fake_awsm

    protected

    def load_fake_awsm
      config_ru = File.join(EY_ROOT, "spec/support/fake_awsm/config.ru")
      unless system("ruby -c '#{config_ru}' > /dev/null")
        raise SyntaxError, "There is a syntax error in fake_awsm/config.ru! fix it!"
      end
      @server = RealWeb.start_server_in_fork(config_ru)
      "http://localhost:#{@server.port}"
    end
  end
end
