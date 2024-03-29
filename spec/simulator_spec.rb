# frozen_string_literal: true

require 'simulator'

SIMULATOR_SPEC_TEN_SECONDS = 10

RSpec.describe Simulator do
  before do
    @logger = double('Logger')
    allow(@logger).to receive(:info)
    allow(@logger).to receive(:warn)
  end

  describe '#new' do
    it 'makes schedule' do
      @obj = Simulator.new(@logger, dummy_data)
      expect(@obj.queue.size).to eq 3
      expect(@obj.simulated).to eq []
      expect(@obj.next.class.to_s).to eq 'Time'
    end
  end

  describe '#fetch_new_odds and #odds' do
    it 'gives a simulated odds stream' do
      @obj = Simulator.new(@logger, dummy_data)
      @obj.fetch_new_odds
      expect(@obj.queue.size).to eq 2
      expect(@obj.simulated.size).to eq 1
      expect(@obj.odds).to eq [[3.2, 3.2, 1.6]]
    end
    it 'gives empty array if without run' do
      @obj = Simulator.new(@logger, dummy_data)
      expect(@obj.odds).to eq []
    end
  end

  describe '#on_fire?' do
    it 'returns false right after setup' do
      @obj = Simulator.new(@logger, dummy_data)
      expect(@obj.on_fire?).to be_falsey
    end
    it 'returns true 60 seconds after setup' do
      @obj = Simulator.new(@logger, dummy_data)
      @obj.next -= 60
      expect(@obj.on_fire?).to be_truthy
    end
  end

  describe '#on_deadline?' do
    it 'returns false if more than 10 seconds until the next schedule' do
      @obj = Simulator.new(@logger, dummy_data)
      expect(@obj.on_deadline?).to be_falsey
    end
    it 'returns true if less than 10 seconds till the next schedule' do
      @obj = Simulator.new(@logger, dummy_data)
      @obj.next -= 50
      expect(@obj.on_deadline?).to be_truthy
    end
  end

  describe '#finished?' do
    it 'returns false if the data stream is NOT finished' do
      @obj = Simulator.new(@logger, dummy_data)
      expect(@obj.finished?).to be_falsey
    end
  end
end

def dummy_data
  [
    {
      at:   Time.now,
      data: [3.2, 3.2, 1.6],
    },
    {
      at:   Time.now + SIMULATOR_SPEC_TEN_SECONDS,
      data: [4.0, 2.67, 1.6],
    },
    {
      at:   Time.now + (2 * SIMULATOR_SPEC_TEN_SECONDS),
      data: [2.67, 2.67, 2.0],
    },
  ]
end
