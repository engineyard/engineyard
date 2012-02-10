require 'dm-core'

class Environment
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :ssh_username, String
  property :app_server_stack_name, String
  property :load_balancer_ip_address, String
  property :framework_env, String

  belongs_to :account
  has n, :app_environments
  has n, :apps, :through => :app_environments
  has n, :instances

  def app_master
    @app_master ||= instances.find { |i| %w[solo app_master].include?(i.role) }
  end

  def inspect
    "#<Environment name:#{name} account:#{account.name}>"
  end

  def to_api_response(nested = true)
    res = {
      "id"                       => id,
      "ssh_username"             => ssh_username,
      "instances"                => instances.map { |i| i.to_api_response },
      "name"                     => name,
      "instances_count"          => instances.size,
      "app_server_stack_name"    => app_server_stack_name,
      "load_balancer_ip_address" => load_balancer_ip_address,
      "framework_env"            => framework_env,
      "app_master"               => app_master && app_master.to_api_response,
      "account"                  => account.to_api_response,
    }
    res["apps"] = apps.map { |app| app.to_api_response(false) } if nested
    res
  end
end
