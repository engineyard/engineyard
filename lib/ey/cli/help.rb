module EY
  module CLI
    class Help
      def self.run(args)
        cmd = args.shift
        
        begin
          klass = CLI.command_to_class(cmd)
        rescue CLI::CommandNotFound
          puts "No such command: #{cmd}"
          exit(1)
        end
        
        if klass.respond_to?(:usage)
          puts klass.usage
        else
          puts "There is no documentation for command: #{cmd}"
        end
      end
      
      def self.short_usage
        "ey help <command>: show full usage information for a specific command"
      end
    end
  end
end