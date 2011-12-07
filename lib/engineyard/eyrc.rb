module EY
  class EYRC
    attr_reader :path

    DEFAULT_PATH = "~/.eyrc"

    def self.load
      new(ENV['EYRC'] || DEFAULT_PATH)
    end

    def initialize(path)
      self.path = path
    end

    def exist?
      path.exist?
    end

    # auto:  on in unix-like shells, off in windows-like shells
    # true:  on in all tty shells
    # false: off always
    def color
      self['color'] || 'auto'
    end

    def api_token
      self['api_token']
    end

    def api_token=(token)
      self['api_token'] = token
    end

    private

    def path=(p)
      @path = Pathname.new(p).expand_path
    end

    def [](key)
      read_data[key.to_s]
    end

    def []=(key,val)
      merge_and_write(key.to_s => val)
      val
    end

    def read_data
      exist? && YAML.load(path.read) || {}
    end

    def merge_and_write(new_data)
      to_write = read_data.merge(new_data)
      path.open("w") {|f| YAML.dump(to_write, f) }
    end

  end
end
