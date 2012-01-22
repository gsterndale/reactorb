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
  it "should execute block passed" do
    expect { subject.run{|r| raise "foo" } }.to raise_error "foo"
  end
  it "should yield itself" do
    subject.run{|r| r.should be subject }
  end
end

describe Reactor, ".run" do
  subject { Reactor }
  it "should execute block passed" do
    expect { subject.run{|r| raise "foo" } }.to raise_error "foo"
  end
  it "should yield instance of itself" do
    subject.run{|r| r.should be_a subject }
  end
end

describe Reactor, "time based events" do
  let(:reactor) { Reactor.new }
  let(:now) { Time.at(1324311324) }
  attr_accessor :tally
  let(:incrementor) { proc { self.tally += 1 } }
  let(:stopper) { proc {|r| reactor.stop } }
  subject { reactor }
  before do
    start = now
    Timecop.freeze(start)
    Reactor.stub(:now) { start += 1 }
    self.tally = 0
  end
  after do
    Timecop.return
  end
  context "added in the past" do
    it "should fire events" do
      subject.in -2, &incrementor
      subject.in -1, &incrementor
      expect { subject.run }.to change { tally }.by(2)
    end
  end
  context "added for the same in the past" do
    it "should fire events" do
      subject.at now-1, &incrementor
      subject.at now-1, &incrementor
      expect { subject.run }.to change { tally }.by(2)
    end
  end
  context "added in the past, stopped" do
    it "should fire events" do
      subject.in -3, &stopper
      subject.in -2, &incrementor
      subject.in -1, &incrementor
      expect { subject.run }.to change { tally }.by(2)
    end
  end
  context "added in the future" do
    it "should fire events" do
      subject.in 5, &incrementor
      subject.in 8, &incrementor
      expect { subject.run }.to change { tally }.by(2)
    end
  end
  context "added in the future, stopped" do
    it "should not fire events" do
      subject.in 1, &stopper
      subject.in 5, &incrementor
      subject.in 8, &incrementor
      expect { subject.run }.not_to change { tally }
    end
  end
end

describe Reactor, "#timer_dispatcher" do
  let(:now) { Time.at(1324311324) }
  let(:delay) { 123 }
  let(:later) { now + delay }
  let(:reactor) { Reactor.new }
  let(:callback) { proc{'foo'} }
  subject { reactor }
  it { should be_empty }
  its(:timer_dispatcher) { should be_empty }
  before do
    Timecop.freeze(now)
  end
  after do
    Timecop.return
  end
  context "a time based event added #in N seconds" do
    before do
      reactor.in(delay, &callback)
    end
    it { should_not be_empty }
    describe "#timer_dispatcher" do
      subject { reactor.timer_dispatcher }
      its(:shift) { should include [callback, []] }
      its(:keys) { should include later.to_i }
    end
  end
  context "a time based event added #at N time" do
    before do
      reactor.at(later, &callback)
    end
    it { should_not be_empty }
    describe "#timer_dispatcher" do
      subject { reactor.timer_dispatcher }
      its(:shift) { should include [callback, []] }
      its(:keys) { should include later.to_i }
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

  its(:event_dispatcher) { should be_empty }

  context "for :read events" do
    before do
      reactor.attach reader, :read, &read_chunk
    end
    its(:event_dispatcher) { should_not be_empty }
    describe "#event_dispatcher" do
      subject { reactor.event_dispatcher }
      its(:keys) { should include reader }
    end

    context "#detach'ed" do
      before do
        reactor.detach reader
      end
      describe "#event_dispatcher" do
        subject { reactor.event_dispatcher }
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

