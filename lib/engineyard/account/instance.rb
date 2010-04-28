module EY
  class Account
    class Instance < ApiStruct.new(:id, :role, :amazon_id, :public_hostname)
    end
  end
end