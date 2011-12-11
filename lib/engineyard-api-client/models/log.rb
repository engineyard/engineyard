module EY
  class APIClient
    class Log < ApiStruct.new(:id, :role, :main, :custom)
      def instance_name
        "#{role} #{id}"
      end
    end
  end
end
