require 'spec_helper'

describe Reactor::HTTP do
  def attach(io, verb, &work)
    work.call(io) while @result.nil?
  end

  def detach(*)
  end

  include Reactor::HTTP

  let(:io)       { double IO, write: nil, close: nil, read_nonblock: response }
  let(:uri)      { URI.parse 'http://example.com/resource/123' }
  let(:response) { "response" }
  let(:handler)  { -> {} }
  let(:result)   { @result }

  before(:example) do
    allow(TCPSocket).to receive_messages(open: io)
    allow(io).to receive(:eof?).and_return(false, true)
    allow(handler).to receive(:call) { |response| @result = response }
  end

  shared_examples "a HTTP request" do |request|
    it "writes request to IO" do
      expect(subject).to have_received(:write).with(a_string_matching request)
    end

    it "closes IO" do
      expect(subject).to have_received(:close)
    end
  end

  shared_examples "a callback" do
    it "called with result" do
      expect(subject).to have_received(:call).with(result)
    end
  end

  %i(get put post delete head).each do |verb|
    describe "##{verb}" do
      before do
        self.send(verb, uri, &handler)
      end

      describe IO do
        subject { io }
        it_behaves_like "a HTTP request", verb.to_s.upcase
      end

      describe "handler" do
        let(:result) { @result }
        subject { handler }
        it_behaves_like "a callback"
      end
    end
  end
end
