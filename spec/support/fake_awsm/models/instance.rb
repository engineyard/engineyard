require 'dm-core'

class Instance
  include DataMapper::Resource

  property :id,              Serial
  property :name,            String
  property :role,            String
  property :status,          String
  property :amazon_id,       String
  property :public_hostname, String

  belongs_to :environment

  def inspect
    "#<Instance environment:#{environment.name} role:#{role} name:#{name}>"
  end

  def to_api_response
    {
      "id"              => id,
      "role"            => role,
      "name"            => name,
      "status"          => status,
      "amazon_id"       => amazon_id,
      "public_hostname" => public_hostname,
    }
  end
end
