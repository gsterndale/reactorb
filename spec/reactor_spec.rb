require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Reactor, "#running?" do
  context "before #run()" do
    it { should_not be_running }
  end
  context "during #run()" do
    it "should be running" do
      subject.run{|r| r.should be_running; r.stop }
    end
  end
  context "after #run()" do
    before { subject.run{|r| r.stop } }
    it { should_not be_running }
  end
end

describe Reactor, "#run" do
  it "should execute block passed" do
    expect { subject.run{|r| raise "foo" } }.to raise_error "foo"
  end
  it "should yield itself" do
    subject.run{|r| r.should be subject; r.stop }
  end
  context "with time based events added in the past" do
    it "should fire events" do
      tally = 0
      subject.run do |r|
        r.at(1){ tally += 1}
        r.at(2){ tally += 1}
        r.at(3){ r.stop }
      end
      tally.should == 2
    end
  end
  context "stopped with time based events added in the past" do
    it "should fire events" do
      tally = 0
      subject.run do |r|
        r.at(1){ r.stop }
        r.at(2){ tally += 1}
        r.at(3){ tally += 1}
      end
      tally.should == 2
    end
  end
  context "with time based events added in the future" do
    it "should fire events" do
      now = Time.now.to_i + 1
      tally = 0
      subject.run do |r|
        r.at(now+1){ tally += 1}
        r.at(now+2){ tally += 1}
        r.at(now+3){ r.stop }
      end
      tally.should == 2
    end
  end
  context "stopped with time based events added in the future" do
    it "should not fire events" do
      now = Time.now.to_i + 1
      tally = 0
      subject.run do |r|
        r.at(now+1){ r.stop }
        r.at(now+2){ tally += 1}
        r.at(now+3){ tally += 1}
      end
      tally.should == 0
    end
  end
end

describe Reactor, "#timers" do
  let(:reactor) { Reactor.new }
  subject { reactor.timers }
  it { should be_empty }
  context "a time based event added" do
    let(:blk) { proc{'foo'} }
    before do
      reactor.at(123, &blk)
    end
    it { should_not be_empty }
    its(:shift) { should == [blk, []] }
  end
end

