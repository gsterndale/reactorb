require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Reactor, "#running?" do
  context "before #run()" do
    it { should_not be_running }
  end
  context "during #run()" do
    it "should be running" do
      subject.run{|r| r.should be_running }
    end
  end
  context "after #run()" do
    before { subject.run }
    it { should_not be_running }
  end
end

describe Reactor, "#run" do
  let(:now) { 1324311324 }
  before do
    start = now
    Timecop.freeze(start)
    Reactor.stub(:now) { start += 1 }
  end
  it "should execute block passed" do
    expect { subject.run{|r| raise "foo" } }.to raise_error "foo"
  end
  it "should yield itself" do
    subject.run{|r| r.should be subject }
  end
  context "with time based events added in the past" do
    it "should fire events" do
      tally = 0
      subject.run do |r|
        r.at(1){ tally += 1}
        r.at(2){ tally += 1}
      end
      tally.should == 2
    end
  end
  context "with time based events added for the same in the past" do
    it "should fire events" do
      tally = 0
      subject.run do |r|
        r.at(1){ tally += 1}
        r.at(1){ tally += 1}
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
      tally = 0
      subject.run do |r|
        r.at(now+1){ tally += 1}
        r.at(now+2){ tally += 1}
      end
      tally.should == 2
    end
  end
  context "stopped with time based events added in the future" do
    it "should not fire events" do
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
  it { should be_empty }
  its(:timers) { should be_empty }
  context "a time based event added" do
    let(:blk) { proc{'foo'} }
    before do
      subject.at(123, &blk)
    end
    it { should_not be_empty }
    it "should have block and args as first value in timers" do
      subject.timers.shift.should include [blk, []]
    end
  end
end

describe Reactor, "with #attach'ed IO" do
  let(:pipe)     { IO.pipe }
  let(:reader)   { pipe[0] }
  let(:writer)   { pipe[1] }
  let(:message)  { "ohai " * 123 }
  let(:sent)     { message.clone }
  let(:received) { '' }
  let(:reactor)  { Reactor.new }
  let(:write_chunk) do
    proc {|io| io.close if io.write(sent.slice!(0..49)) < 50 }
  end
  let(:read_chunk) do
    proc {|io| received << (io.read(10) || io.close || '') }
  end
  subject { reactor }

  its(:ios) { should be_empty }

  context "for :read events" do
    before do
      reactor.attach reader, :read, &read_chunk
    end
    its(:ios) { should_not be_empty }
    describe "#ios" do
      subject { reactor.ios }
      its(:keys) { should include reader }
    end

    context "#detach'ed" do
      before do
        reactor.detach reader
      end
      describe "#ios" do
        subject { reactor.ios }
        its(:keys) { should_not include reader }
      end
    end
  end

  context "#run" do
    it "should read entire message in IO #attach'ed to :read" do
      writer.write(sent)
      writer.close
      reactor.attach reader, :read, &read_chunk
      subject.run
      received.should == message
    end
    it "should write entire message from IO #attach'ed to :write" do
      reactor.attach writer, :write, &write_chunk
      subject.run
      reader.read.should == message
      reader.close
    end
    it "should transfer entire message from one #attach'ed IO to another" do
      subject.run do |reactor|
        reactor.attach writer, :write, &write_chunk
        reactor.attach reader, :read, &read_chunk
      end
      received.should == message
    end
  end
end

