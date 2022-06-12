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
      pat_info_got_data = /INFO \-\- : DataManager got data: \[\{:at=>/
      expect(is_included_in_log?(pat_info_got_data)).to be_truthy
    end
    it 'gives false flags' do
      expect(@obj.converge).to be_falsey
      expect(@obj.summarized).to be_falsey
    end
  end

  describe '#is_on_fire' do
    it 'adds an INFO log "Performed"' do
      pat_info_performed = /INFO \-\- : Performed!!/
      expect {
        until @obj.is_on_fire do sleep(1) end
      }.to change{is_included_in_log?(pat_info_performed)}.from(false).to(true)
    end
  end

  describe '#run' do
    it 'adds an INFO log "Got odds"' do
      pat_info_got_odds = /INFO \-\- : Got odds:/
      until @obj.is_on_fire do sleep(1) end
      expect {
        @obj.run
      }.to change{is_included_in_log?(pat_info_got_odds)}.from(false).to(true)
    end
  end

  describe '#learn' do
  end

  describe '#finalize' do
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
