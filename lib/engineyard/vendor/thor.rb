require 'thor/base'

# TODO: Update thor to allow for git-style CLI (git bisect run)
class Thor
  class << self
    # Sets the default task when thor is executed without an explicit task to be called.
    #
    # ==== Parameters
    # meth<Symbol>:: name of the defaut task
    #
    def default_task(meth=nil)
      case meth
        when :none
          @default_task = 'help'
        when nil
          @default_task ||= from_superclass(:default_task, 'help')
        else
          @default_task = meth.to_s
      end
    end

    # Defines the usage and the description of the next task.
    #
    # ==== Parameters
    # usage<String>
    # description<String>
    #
    def desc(usage, description, options={})
      if options[:for]
        task = find_and_refresh_task(options[:for])
        task.usage = usage             if usage
        task.description = description if description
      else
        @usage, @desc = usage, description
      end
    end

    # Defines the long description of the next task.
    #
    # ==== Parameters
    # long description<String>
    #
    def long_desc(long_description, options={})
      if options[:for]
        task = find_and_refresh_task(options[:for])
        task.long_description = long_description if long_description
      else
        @long_desc = long_description
      end
    end

    # Maps an input to a task. If you define:
    #
    #   map "-T" => "list"
    #
    # Running:
    #
    #   thor -T
    #
    # Will invoke the list task.
    #
    # ==== Parameters
    # Hash[String|Array => Symbol]:: Maps the string or the strings in the array to the given task.
    #
    def map(mappings=nil)
      @map ||= from_superclass(:map, {})

      if mappings
        mappings.each do |key, value|
          if key.respond_to?(:each)
            key.each {|subkey| @map[subkey] = value}
          else
            @map[key] = value
          end
        end
      end

      @map
    end

    # Declares the options for the next task to be declared.
    #
    # ==== Parameters
    # Hash[Symbol => Object]:: The hash key is the name of the option and the value
    # is the type of the option. Can be :string, :array, :hash, :boolean, :numeric
    # or :required (string). If you give a value, the type of the value is used.
    #
    def method_options(options=nil)
      @method_options ||= {}
      build_options(options, @method_options) if options
      @method_options
    end

    # Adds an option to the set of method options. If :for is given as option,
    # it allows you to change the options from a previous defined task.
    #
    #   def previous_task
    #     # magic
    #   end
    #
    #   method_option :foo => :bar, :for => :previous_task
    #
    #   def next_task
    #     # magic
    #   end
    #
    # ==== Parameters
    # name<Symbol>:: The name of the argument.
    # options<Hash>:: Described below.
    #
    # ==== Options
    # :desc     - Description for the argument.
    # :required - If the argument is required or not.
    # :default  - Default value for this argument. It cannot be required and have default values.
    # :aliases  - Aliases for this option.
    # :type     - The type of the argument, can be :string, :hash, :array, :numeric or :boolean.
    # :banner   - String to show on usage notes.
    #
    def method_option(name, options={})
      scope = if options[:for]
        find_and_refresh_task(options[:for]).options
      else
        method_options
      end

      build_option(name, options, scope)
    end

    # Parses the task and options from the given args, instantiate the class
    # and invoke the task. This method is used when the arguments must be parsed
    # from an array. If you are inside Ruby and want to use a Thor class, you
    # can simply initialize it:
    #
    #   script = MyScript.new(args, options, config)
    #   script.invoke(:task, first_arg, second_arg, third_arg)
    #
    def start(original_args=ARGV, config={})
      super do |given_args|
        meth = given_args.first.to_s

        if !meth.empty? && (map[meth] || meth !~ /^\-/)
          given_args.shift
        else
          meth = nil
        end

        meth = normalize_task_name(meth)
        task = all_tasks[meth]

        if task
          args, opts = Thor::Options.split(given_args)
          config.merge!(:task_options => task.options)
        else
          args, opts = given_args, {}
        end

        task ||= Thor::Task::Dynamic.new(meth)
        trailing = args[Range.new(arguments.size, -1)]
        new(args, opts, config).invoke(task, trailing || [])
      end
    end

    # Prints help information for the given task.
    #
    # ==== Parameters
    # shell<Thor::Shell>
    # task_name<String>
    #
    def task_help(shell, task_name)
      meth = normalize_task_name(task_name)
      task = all_tasks[meth]
      handle_no_task_error(meth) unless task

      shell.say "Usage:"
      shell.say "  #{banner(task)}"
      shell.say
      class_options_help(shell, nil => task.options.map { |_, o| o })
      if task.long_description
        shell.say "Description:"
        shell.print_wrapped(task.long_description, :ident => 2)
      else
        shell.say task.description
      end
    end

    # Prints help information for this class.
    #
    # ==== Parameters
    # shell<Thor::Shell>
    #
    def help(shell)
      list = printable_tasks
      Thor::Util.thor_classes_in(self).each do |klass|
        list += klass.printable_tasks(false)
      end
      list.sort!{ |a,b| a[0] <=> b[0] }

      shell.say "Tasks:"
      shell.print_table(list, :ident => 2, :truncate => true)
      shell.say
      class_options_help(shell)
    end

    # Returns tasks ready to be printed.
    def printable_tasks(all=true)
      (all ? all_tasks : tasks).map do |_, task|
        item = []
        item << banner(task)
        item << (task.description ? "# #{task.description.gsub(/\s+/m,' ')}" : "")
        item
      end
    end

    def handle_argument_error(task, error) #:nodoc:
      raise InvocationError, "#{task.name.inspect} was called incorrectly. Call as #{task.formatted_usage(self, banner_base == "thor").inspect}."
    end

    protected

      # The banner for this class. You can customize it if you are invoking the
      # thor class by another ways which is not the Thor::Runner. It receives
      # the task that is going to be invoked and a boolean which indicates if
      # the namespace should be displayed as arguments.
      #
      def banner(task)
        "#{banner_base} #{task.formatted_usage(self, banner_base == "thor")}"
      end

      def baseclass #:nodoc:
        Thor
      end

      def create_task(meth) #:nodoc:
        if @usage && @desc
          tasks[meth.to_s] = Thor::Task.new(meth, @desc, @long_desc, @usage, method_options)
          @usage, @desc, @long_desc, @method_options = nil
          true
        elsif self.all_tasks[meth.to_s] || meth.to_sym == :method_missing
          true
        else
          puts "[WARNING] Attempted to create task #{meth.inspect} without usage or description. " <<
               "Call desc if you want this method to be available as task or declare it inside a " <<
               "no_tasks{} block. Invoked from #{caller[1].inspect}."
          false
        end
      end

      def initialize_added #:nodoc:
        class_options.merge!(method_options)
        @method_options = nil
      end

      # Receives a task name (can be nil), and try to get a map from it.
      # If a map can't be found use the sent name or the default task.
      #
      def normalize_task_name(meth) #:nodoc:
        meth = map[meth.to_s] || meth || default_task
        meth.to_s.gsub('-','_') # treat foo-bar > foo_bar
      end
  end

  include Thor::Base

  map HELP_MAPPINGS => :help

  desc "help [TASK]", "Describe available tasks or one specific task"
  def help(task=nil)
    task ? self.class.task_help(shell, task) : self.class.help(shell)
  end
end
