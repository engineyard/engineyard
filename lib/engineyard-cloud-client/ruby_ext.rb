class Object
  unless respond_to?(:tap)
    # Ruby 1.9 has it, 1.8 doesn't
    def tap
      yield self
      self
    end
  end
end
