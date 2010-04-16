class Log < Struct.new(:id, :role, :main, :custom)
  def self.from_hash(hash)
    new(
      hash["id"],
      hash["role"],
      hash["main"],
      hash["custom"]
    ) if hash && hash != "null"
  end

  def self.from_array(array)
    array.map{|n| from_hash(n) } if array && array != "null"
  end

  def instance_name
    "#{role} #{id}"
  end
end
