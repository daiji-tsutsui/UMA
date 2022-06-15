# frozen_string_literal: true

require 'scheduler'

SCHEDULER_SPEC_TEN_MINUTES = 60 * 10

RSpec.describe Scheduler do
  before do
    @logger = double('Logger')
    allow(@logger).to receive(:info)
  end

  describe '#new' do
    it 'makes schedule' do
      allow(YAML).to receive(:load_file).with('schedule.yaml')
                                        .and_return(dummy_data1)
      @obj = Scheduler.new(@logger)
      expect(@obj.next.class.to_s).to eq 'Time'
      expect(@obj.next.to_s).to eq '1993-04-17 15:03:00 +0900'
    end
  end

  describe '#is_on_fire' do
    it 'returns false if the scheduler is finished' do
      allow(YAML).to receive(:load_file).with('schedule.yaml')
                                        .and_return(dummy_data1)
      @obj = Scheduler.new(@logger)
      expect(@obj.is_on_fire).to be_falsey
    end
    it 'returns true if the scheduler is on fire' do
      allow(YAML).to receive(:load_file).with('schedule.yaml')
                                        .and_return(dummy_data2)
      @obj = Scheduler.new(@logger)
      expect(@obj.is_on_fire).to be_truthy
      expect(@obj.is_on_fire).to be_falsey
    end
  end

  describe '#is_on_deadline' do
    it 'returns true independet of if is finished' do
      allow(YAML).to receive(:load_file).with('schedule.yaml')
                                        .and_return(dummy_data1)
      @obj = Scheduler.new(@logger)
      expect(@obj.is_on_deadline).to be_truthy
    end
    it 'returns false if more than 10 seconds before the next schedule' do
      allow(YAML).to receive(:load_file).with('schedule.yaml')
                                        .and_return(dummy_data2)
      @obj = Scheduler.new(@logger)
      expect(@obj.is_on_deadline).to be_truthy
      expect(@obj.is_on_fire).to be_truthy      # fetch next
      expect(@obj.is_on_deadline).to be_falsey
    end
    it 'returns true if less than 10 seconds before the next schedule' do
      allow(YAML).to receive(:load_file).with('schedule.yaml')
                                        .and_return(dummy_data3)
      @obj = Scheduler.new(@logger)
      expect(@obj.is_on_deadline).to be_truthy
      expect(@obj.is_on_fire).to be_truthy      # fetch next
      expect(@obj.is_on_deadline).to be_truthy
    end
  end

  describe '#is_finished' do
    it 'returns true if the scheduler is finished' do
      allow(YAML).to receive(:load_file).with('schedule.yaml')
                                        .and_return(dummy_data1)
      @obj = Scheduler.new(@logger)
      expect(@obj.is_finished).to be_truthy
    end
    it 'returns false if the scheduler is NOT finished' do
      allow(YAML).to receive(:load_file).with('schedule.yaml')
                                        .and_return(dummy_data2)
      @obj = Scheduler.new(@logger)
      expect(@obj.is_finished).to be_falsey
    end
  end
end

def dummy_data1
  {
    'start' => Time.parse("1993-04-17 15:03:00 +0900"),
    'end' => Time.parse("1993-04-17 15:25:20 +0900"),
    'rule' => [
      { 'duration' => 960, 'interval' => 240 },
      { 'duration' => 600, 'interval' => 120 },
    ]
  }
end

def dummy_data2
  {
    'start' => Time.now,
    'end' => Time.now + SCHEDULER_SPEC_TEN_MINUTES,
    'rule' => [
      { 'duration' => 400, 'interval' => 100 },
      { 'duration' => 200, 'interval' => 50 },
    ]
  }
end

def dummy_data3
  {
    'start' => Time.now,
    'end' => Time.now + SCHEDULER_SPEC_TEN_MINUTES,
    'rule' => [
      { 'duration' => 400, 'interval' => 10 },
      { 'duration' => 200, 'interval' => 50 },
    ]
  }
end