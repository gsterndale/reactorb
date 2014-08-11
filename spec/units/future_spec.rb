require 'spec_helper'

describe Reactor::Future do

  class Worker
    attr_accessor :handler, :result

    def initialize(result)
      @result = result
    end

    def work(complete = false)
      handler.call(result) if !!complete
    end
  end

  let(:result) { double :result, foo: :bar }

  let(:worker) { Worker.new(result) }

  subject(:future) do
    Reactor::Future.start do |handler|
      worker.handler = handler
    end
  end

  context "handler called" do
    around(:each) do |example|
      block_executed = false
      Fiber.new do
        example.run
        block_executed = true
      end.resume
      fail if block_executed
      worker.work(false)
      fail if block_executed
      worker.work(true)
      fail unless block_executed
    end

    it { is_expected.to eql result }
    its(:foo) { is_expected.to eql :bar }
  end
end
