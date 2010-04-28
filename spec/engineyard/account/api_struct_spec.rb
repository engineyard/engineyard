require 'spec_helper'

describe EY::Account::ApiStruct do
  class Foo < EY::Account::ApiStruct.new(:fruit); end
  class FooWithAccount < EY::Account::ApiStruct.new(:fruit, :account); end

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

    it "handles an account as the second argument" do
      f = FooWithAccount.from_array([:fruit => "banana"], "account")
      f.should == [FooWithAccount.new("banana", "account")]
    end
  end

end