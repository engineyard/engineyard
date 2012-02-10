require 'dm-core'

class User
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :email, String

  has n, :accounts

  def to_api_response
    {
      "id"    => id,
      "name"  => name,
      "email" => email,
    }
  end
end
