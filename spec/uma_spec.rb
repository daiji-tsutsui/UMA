# frozen_string_literal: true

require 'uma'

UMA_SPEC_TEN_MINUTES = 10 * 60
UMA_SPEC_TEN_SECONDS = 10

RSpec.describe Uma do
  before do
    ENV['SIMULATOR_FIRST_WAIT'] = '1'
    @obj = Uma.new(
      simulate:   true,
      simfile:    'dummy_for_test',
    )
  end
  after do
    FileUtils.rm(Dir.glob("./log/*_dummy_for_test.log"))
  end

  describe '#new' do
    it 'adds an INFO log "Datamanager"' do
      pat_info_got_data = /INFO -- : DataManager got data: \[\{:at=>/
      expect(is_included_in_log?(pat_info_got_data)).to be_truthy
    end
    it 'gives false flags' do
      expect(@obj.converge).to be_falsey
      expect(@obj.summarized).to be_falsey
    end
  end

  describe '#is_on_fire' do
    it 'adds an INFO log "Performed"' do
      pat_info_performed = /INFO -- : Performed!!/
      expect {
        until @obj.is_on_fire do sleep(1) end
      }.to change{ is_included_in_log?(pat_info_performed) }.from(false).to(true)
    end
  end

  describe '#run' do
    it 'adds an INFO log "Got odds"' do
      pat_info_got_odds = /INFO -- : Got odds:/
      until @obj.is_on_fire do sleep(1) end
      expect {
        @obj.run
      }.to change{ is_included_in_log?(pat_info_got_odds) }.from(false).to(true)
    end
  end

  describe '#learn' do
    before do
      until @obj.is_on_fire do sleep(1) end
      @obj.run
    end

    it 'changes summarized flag' do
      expect {
        @obj.learn
      }.to change{ @obj.summarized }.from(false).to(true)
    end

    context 'without args' do
      it 'adds an INFO log "Summary"' do
        pat_info_summary = /INFO -- : Summary:/
        expect {
          @obj.learn
        }.to change{ is_included_in_log?(pat_info_summary) }.from(false).to(true)
      end
      it 'does not add an INFO log "Loss"' do
        pat_info_loss = /INFO -- : Loss:/
        @obj.learn
        expect(is_included_in_log?(pat_info_loss)).to be_falsey
      end
    end

    context 'with check_loss flag true' do
      it 'adds an INFO log "Summary"' do
        pat_info_summary = /INFO -- : Summary:/
        expect {
          @obj.learn(check_loss: true)
        }.to change{ is_included_in_log?(pat_info_summary) }.from(false).to(true)
      end
      it 'adds an INFO log "Loss"' do
        pat_info_loss = /INFO -- : Loss:/
        expect {
          @obj.learn(check_loss: true)
        }.to change{is_included_in_log?(pat_info_loss)}.from(false).to(true)
      end
    end
  end

  describe '#finalize' do
    it 'returns false until the schedule is finished' do
      expect(@obj.finalize).to be_falsey
    end
  end
end

def is_included_in_log?(pattern)
  filename = "./log/#{Time.now.strftime("%Y%m%d_%H%M")}_dummy_for_test.log"
  File.open(filename, 'r') do |f|
    f.each_line do |line|
      return true if line =~ pattern
    end
  end
  false
end
