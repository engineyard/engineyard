class Integer
  def retries(&block)
    @retries ||= 0
    @retries += 1
    yield if block_given?
    retry unless @retries > self
  end
end
