class EY::CLI::Token < EY::Token

  def initialize(token = nil)
    super(token)
    @token ||= self.class.from_cloud
  end

  def request(*)
    begin
      super
    rescue EY::API::InvalidCredentials
      EY.ui.warn "Credentials rejected, please authenticate again"
      refresh
      retry
    end
  end

  def refresh
    @token = self.class.from_cloud
  end

  def self.from_cloud
    EY.ui.info("We need to fetch your API token, please login")
    begin
      email    ||= EY.ui.ask("Email: ")
      password ||= EY.ui.ask("Password: ", true)
      super(email, password)
    rescue EY::API::InvalidCredentials
      EY.ui.warn "Invalid username or password, please try again"
      retry
    end
  end

end