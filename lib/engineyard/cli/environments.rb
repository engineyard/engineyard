module EY
  module CLI
    class Environments < Command
      def self.run(args)
        envs = token.request('/environments', :method => :get)

        if envs.empty?
          puts "You have no cloud environments."
        else
          puts "Cloud environments:"
          envs.each do |e|
            icount = e["instances"].size
            iname = (icount == 1) ? "instance" : "instances"
            puts "  #{e["name"]}, #{icount} #{iname}"
          end
        end
      end

      def self.short_usage
        "ey environments: list the cloud environments for the app in the current directory"
      end
    end
  end
end