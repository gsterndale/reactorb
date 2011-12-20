require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CallbackRegistry, ".new" do
  it "values should default to an empty array" do
    subject["foo"].should == []
  end
end

describe CallbackRegistry, "with keys" do
  let(:key1) { 1 }
  let(:key2) { 2 }
  let(:key3) { 3 }
  let(:value1) { 'won' }
  let(:value2) { 'too' }
  let(:value3) { 'tree' }
  subject do
    CallbackRegistry.new.tap do |cr|
      cr[key3] << value3
      cr[key1] << value1
      cr[key2] << value2
    end
  end
  its(:first_key) { should be key1 }
  its(:shift) { should == [value1] }
  its(:shift_pair) { should == [key1, [value1]] }
  describe "#shift'ed" do
    before { subject.shift }
    its(:first_key) { should be key2 }
  end
end
