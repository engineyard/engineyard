require 'spec_helper'

describe EY::CloudClient::ApiStruct do
  class Foo < EY::CloudClient::ApiStruct.new(:fruit, :veggie); end

  it "acts like a normal struct" do
    f = Foo.new(ey_api, "fruit" => "banana")

    f.fruit.should == "banana"
  end

  describe "from_hash initializer" do
    it "assigns values from string keys" do
      f = Foo.from_hash(ey_api, "fruit" => "banana")
      f.should == Foo.new(ey_api, "fruit" => "banana")
    end

    it "assigns values from symbol keys" do
      f = Foo.from_hash(ey_api, :fruit => "banana")
      f.should == Foo.new(ey_api, "fruit" => "banana")
    end
  end

  describe "from_array initializer" do
    it "provides a from_array initializer" do
      f = Foo.from_array(ey_api, [:fruit => "banana"])
      f.should == [Foo.new(ey_api, "fruit" => "banana")]
    end

    it "handles a common-arguments hash as the second argument" do
      foos = Foo.from_array(ey_api,
        [{:fruit => "banana"}, {:fruit => 'apple'}],
        :veggie => 'kale')
      foos.should == [
        Foo.new(ey_api, "fruit" => "banana", "veggie" => "kale"),
        Foo.new(ey_api, "fruit" => "apple",  "veggie" => "kale"),
      ]
    end
  end

end
