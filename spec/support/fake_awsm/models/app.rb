require 'gitable'
require 'dm-core'

class App
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :repository_uri, String

  belongs_to :account
  has n, :app_environments
  has n, :environments, :through => :app_environments

  def gitable_uri
    Gitable::URI.parse(repository_uri)
  end

  def inspect
    "#<App name:#{name} account:#{account.name}>"
  end

  def to_api_response(nested = true)
    res = {
      "id"             => id,
      "name"           => name,
      "repository_uri" => repository_uri,
      "account"        => account.to_api_response,
    }
    res['environments'] = environments.map { |env| env.to_api_response(false) } if nested
    res
  end
end
