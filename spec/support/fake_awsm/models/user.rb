require 'dm-core'

class User
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :email, String, :default => 'test@test.test'
  property :password, String, :default => 'test'
  property :api_token, String,
    :default => lambda { |r, p| File.open('/dev/urandom', 'r') { |fh| fh.read(16).unpack('H*').first }}

  has n, :accounts

  def to_api_response
    {
      "id"    => id,
      "name"  => name,
      "email" => email,
    }
  end
end
