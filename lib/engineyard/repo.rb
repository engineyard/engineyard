require 'grit'

module EY
  class Repo
    def initialize(path=File.expand_path('.'))
      @repo = Grit::Repo.new(path)
    end

    def current_branch
      @repo.head.name
    end
  end
end