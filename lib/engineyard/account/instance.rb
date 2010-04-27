class Instance < Struct.new(:id, :role, :amazon_id, :public_hostname)
  def self.from_hash(hash)
    new(
      hash["id"],
      hash["role"],
      hash["amazon_id"],
      hash["public_hostname"]
    ) if hash
  end

  def self.from_array(array)
    if array
      array.map{|n| from_hash(n) }
    else
      []
    end
  end

  def ==(other)
    self.id == other.id &&
    self.role == other.role &&
    self.amazon_id == other.amazon_id &&
    self.public_hostname == other.public_hostname
  end
end
