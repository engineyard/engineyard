module EY
  class APIClient
    class User < ApiStruct.new(:id, :name, :email)
    end
  end
end
