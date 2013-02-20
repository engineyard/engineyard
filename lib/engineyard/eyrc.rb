module EY
  class EYRC
    attr_reader :path

    DEFAULT_PATH = "~/.eyrc"

    def self.load
      new(ENV['EYRC'] || DEFAULT_PATH)
    end

    def initialize(path)
      @path = Pathname.new(path).expand_path
    end

    def exist?
      path.exist?
    end

    def delete_api_token
      delete('api_token')
    end

    def api_token
      self['api_token']
    end

    def api_token=(token)
      self['api_token'] = token
    end

    private

    def [](key)
      read_data[key.to_s]
    end

    def []=(key,val)
      new_data = read_data.merge(key.to_s => val)
      write_data new_data
      val
    end

    def delete(key)
      data = read_data.dup
      res = data.delete(key)
      write_data data
      res
    end

    def read_data
      exist? && YAML.load(path.read) || {}
    end

    def write_data(new_data)
      path.open("w") {|f| YAML.dump(new_data, f) }
    end

  end
end
