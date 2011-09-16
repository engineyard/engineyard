module EY
  module Model
    class App < ApiStruct.new(:id, :account, :name, :repository_uri, :environments, :api)
      extend EY::UtilityMethods

      def self.from_hash(hash)
        super.tap do |app|
          app.environments = Environment.from_array(app.environments, :api => app.api)
          app.account = Account.from_hash(app.account)
        end
      end

      def self.from_array(*)
        Collection::Apps[*super]
      end


      def self.create(options)
        account = options[:account] || fetch_account
        app = {
          :name => options[:name] || File.basename(Dir.pwd),
          :repository_uri => options[:repository_uri] || Repo.new(Dir.pwd).origin_url,
          :app_type_id => options[:type] || detect_app_type
        }

        data = api.request("/accounts/#{account}/apps", {:params => {:app => app}, :method => :post})
        from_hash(data["app"])
      end

      def sole_environment
        if environments.size == 1
          environments.first
        end
      end

      def sole_environment!
        sole_environment or raise NoSingleEnvironmentError.new(self)
      end

      def last_deployment_on(environment)
        Deployment.last(self, environment, api)
      end

      def new_environment_url
        "#{EY.config.endpoint}/apps/#{id}/environments/new"
      end

      private

      def self.detect_app_type
        # should this be done at server side?
        if file_exist?('config.ru') && file_exist?('config/environment.rb')
          :rails3
        elsif file_exist?('config/environment.rb')
          :rails2
        elsif file_exist?('config.ru')
          :rack
        else
          :rails3 #default
        end
      end

      def self.fetch_account
        1 # FIXME!!!!!!!!!!!
      end

      def self.file_exist?(file, root = Dir.pwd)
        File.exist?(File.expand_path(file, root))
      end
    end
  end
end
