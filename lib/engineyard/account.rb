module EY
  class Account

    def initialize(api)
      @api = api
    end

    def environments
      return @environments if @environments
      data = @api.request('/environments', :method => :get)["environments"]
      @environments = Environment.from_array(data || [])
    end

    def apps
      return @apps if @apps
      data  = @api.request('/apps', :method => :get)["apps"]
      @apps = App.from_array(data || [])
    end

    def app_for_repo(repo)
      apps.find{|a| a.repository_uri == repo.uri }
    end

    # Classes to represent the returned data
    class Environment < Struct.new(:name, :instances_count, :apps, :app_master)
      def self.from_hash(hash)
        new(
          hash["name"],
          hash["instances_count"],
          App.from_array(hash["apps"]),
          AppMaster.from_hash(hash["app_master"])
        ) if hash && hash != "null"
      end

      def self.from_array(array)
        array.map{|n| from_hash(n) } if array && array != "null"
      end

      def configuration
        EY.config.environments[self.name]
      end
      alias_method :config, :configuration
    end

    class App < Struct.new(:name, :repository_uri, :environments)
      def self.from_hash(hash)
        new(
          hash["name"],
          hash["repository_uri"],
          Environment.from_array(hash["environments"])
        ) if hash && hash != "null"
      end

      def self.from_array(array)
        array.map{|n| from_hash(n) } if array && array != "null"
      end
    end

    class AppMaster < Struct.new(:status, :ip_address)
      def self.from_hash(hash)
        new(
          hash["status"],
          hash["ip_address"]
        ) if hash && hash != "null"
      end
    end

  end # Account
end # EY
