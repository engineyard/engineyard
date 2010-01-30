module EY
  module CLI
    class Environments < Command
      def self.run(args)
        apps = token.request('/apps', :method => :get)["apps"]
        app  = apps.find{|a| a["repository_uri"] == repo_url }

        envs = (app && app["environments"]) || []

        if envs.empty?
          envs = token.request('/environments', :method => :get)["environments"]
          return puts(%{You do not have any cloud environments.}) if envs.empty?

          puts %{You have no cloud environments set up for the repository "#{repo_url}".}
          puts %{Cloud environments:}
        else
          puts %{Cloud environments for #{app["name"]}:}
        end

        # List envs
        envs.each do |e|
          icount = e["instances_count"]
          iname = (icount == 1) ? "instance" : "instances"
          env = "  #{e["name"]}, #{icount} #{iname}"
          env << " (default)" if e["name"] == config.default_environment
          puts env
        end
      end

      def self.short_usage
        "ey environments: list the cloud environments for the app in the current directory"
      end
    end
  end
end