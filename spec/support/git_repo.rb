module Spec
  module GitRepo
    def define_git_repo(name, &setup)
      # EY's ivars don't get cleared between examples, so we can keep
      # a git repo around longer (and thus make our tests faster)
      EY.define_git_repo(name, &setup)
    end

    def use_git_repo(repo_name)
      before(:each) do
        @_original_wd ||= []
        @_original_wd << Dir.getwd
        Dir.chdir(EY.git_repo_dir(repo_name))
      end

      after(:each) do
        Dir.chdir(@_original_wd.pop)
      end
    end
  end
end
