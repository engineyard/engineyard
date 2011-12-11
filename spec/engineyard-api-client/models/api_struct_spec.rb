require 'spec_helper'

describe EY::APIClient::ApiStruct do
  class Foo < EY::APIClient::ApiStruct.new(:fruit, :veggie); end

  it "acts like a normal struct" do
    f = Foo.new("banana")

    f.fruit.should == "banana"
  end

  describe "from_hash initializer" do
    it "assigns values from string keys" do
      f = Foo.from_hash("fruit" => "banana")
      f.should == Foo.new("banana")
    end

    it "assigns values from symbol keys" do
      f = Foo.from_hash(:fruit => "banana")
      f.should == Foo.new("banana")
    end
  end

  describe "from_array initializer" do
    it "provides a from_array initializer" do
      f = Foo.from_array([:fruit => "banana"])
      f.should == [Foo.new("banana")]
    end

    it "handles a common-arguments hash as the second argument" do
      foos = Foo.from_array(
        [{:fruit => "banana"}, {:fruit => 'apple'}],
        :veggie => 'kale')
      foos.should == [
        Foo.new("banana", "kale"),
        Foo.new("apple", "kale"),
      ]
    end
  end

end
