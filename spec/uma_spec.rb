# frozen_string_literal: true

require 'uma'

UMA_SPEC_TEN_MINUTES = 10 * 60
UMA_SPEC_TEN_SECONDS = 10

RSpec.describe Uma do
  before do
    ENV['SIMULATOR_FIRST_WAIT'] = '0'
    ENV['SIMULATOR_END_WAIT'] = '0'
    ENV['SCHEDULER_DEADLINE_ROOM_UNTIL_FIRE'] = '0.2'
    ENV['UMA_LEARNING_INTERVAL'] = '1'
    ENV['UMA_LEARNING_WAIT'] = '0.05'
    ENV['UMA_IDLING_WAIT'] = '1.0'
    @obj = Uma.new(
      simulate: true,
      simfile:  'dummy_for_test',
    )
    @filename = "./log/#{Time.now.strftime('%Y%m%d_%H%M')}_dummy_for_test.log"
  end
  after do
    FileUtils.rm(Dir.glob('./log/*_dummy_for_test.log'))
  end

  describe '#new' do
    it 'adds an INFO log "Datamanager"' do
      pat_info_got_data = /INFO -- : DataManager got data: \[\{:at=>/
      expect(is_included_in_log?(@filename, pat_info_got_data)).to be_truthy
    end
    it 'gives false flags' do
      expect(@obj.converge).to be_falsey
      expect(@obj.summarized).to be_falsey
    end
  end

  describe '#run' do
    it 'adds an INFO log "Performed"' do
      pat_info_performed = /INFO -- : Performed!!/
      expect { @obj.run }.to change { is_included_in_log?(@filename, pat_info_performed) }.from(false).to(true)
    end
    it 'adds an INFO log "Got odds"' do
      pat_info_got_odds = /INFO -- : Got odds:/
      expect { @obj.run }.to change { is_included_in_log?(@filename, pat_info_got_odds) }.from(false).to(true)
    end
    it 'adds an INFO log "Summary"' do
      pat_info_summary = /INFO -- : Summary:/
      expect { @obj.run }.to change { is_included_in_log?(@filename, pat_info_summary) }.from(false).to(true)
    end
    it 'adds an INFO log "Loss"' do
      pat_info_loss = /INFO -- : Loss:/
      expect { @obj.run }.to change { is_included_in_log?(@filename, pat_info_loss) }.from(false).to(true)
    end
  end
end

def is_included_in_log?(filename, pattern)
  File.open(filename, 'r') do |f|
    f.each_line do |line|
      return true if line =~ pattern
    end
  end
  false
end
