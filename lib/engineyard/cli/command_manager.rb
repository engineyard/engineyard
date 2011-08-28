require 'rubygems' # we need searching through installed gems and finding out which want to extend the ey gem.

module EY
  class CLI < EY::Thor
    class CommandManager
      
      def self.register_class(name,path)
        # load a EY::CLI::NewCommand TODO verify there are no collisions (previously loaded) and that the class actually exists 
        # in the file we are loading and how we expect it (Thor etc.).
        load path
        add_command(name,path)
      end
            
      def self.all_registered_commands
        EY::CLI.all_tasks
      end
    
      # Convention: Use rubygems to find all installed gems that have a ey_plugin.rb file within, using the #register_class method.
      def self.init_plugins!
        Gem.find_files("ey_plugin").each do |extension|
          load extension
        end
      end
      
   protected
   
   def self.add_command(name,path)
     klass = name.capitalize.gsub(/_(.)/) { $1.upcase }.to_sym
     new_class = EY::CLI.const_get(klass)
     EY::CLI.class_eval do
       autoload klass, path
       desc "demo", "Commands related to demo."
       subcommand "demo", new_class
     end
   end
      
    end
  end
end