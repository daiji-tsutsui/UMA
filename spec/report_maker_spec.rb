require 'report_maker'

RSpec.describe ReportMaker do
  before do
    @logger = double('Logger')
    allow(@logger).to receive(:info)
    @analyzer = double('OddsAnalyzer')
    allow(@analyzer).to receive(:a).and_return(dummy_a)
    allow(@analyzer).to receive(:b).and_return(dummy_b)
    allow(@analyzer).to receive(:t).and_return(dummy_t)
    allow(@analyzer).to receive(:strat).and_return(dummy_strat)
    allow(@analyzer).to receive(:probable_strat).and_return(dummy_pstrat)
  end

  describe '#new' do
    it 'returns a summarizer' do
      obj = ReportMaker.new(@analyzer, @logger)
      expect(obj.class.to_s).to eq 'ReportMaker'
      expect(obj.report).to eq nil
    end
  end

  describe '#summarize' do
    before do
      @obj = ReportMaker.new(@analyzer, @logger)
      @odds = [3.2, 4.0, 1.45]
    end

    it 'gives a simple prefix' do
      @obj.summarize(@odds)
      expect(@obj.report).to match /\ASummary:\n\n/
    end
    it 'gives necessary terms' do
      @obj.summarize(@odds)
      expect(@obj.report).to match /^      time \|/
      expect(@obj.report).to match /^    weight \|/
      expect(@obj.report).to match /^ certainty \|/
      expect(@obj.report).to match /^         horse \|/
      expect(@obj.report).to match /^   probability \|/
      expect(@obj.report).to match /^  current odds \|/
      expect(@obj.report).to match /^  optimal odds \|/
      expect(@obj.report).to match /^    weak strat \|/
      expect(@obj.report).to match /^  strong strat \|/
      expect(@obj.report).to match /^  probable st. \|/
    end
  end
end

def dummy_a
  Probability.new([0.25, 0.25, 0.25, 0.25])
end

def dummy_b
  Positives.new([1.0, 1.0, 1.0, 1.0])
end

def dummy_t
  Probability.new([0.2, 0.3, 0.5])
end

def dummy_strat
  Probability.new([0.3, 0.4, 0.3])
end

def dummy_pstrat
  [0.3, 0.4, 0.0]
end