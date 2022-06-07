require 'odds_fetcher'

RSpec.describe OddsFetcher do
  describe '#new' do
    it 'gives accessors' do
      obj = OddsFetcher.new
      expect(obj.odds).to eq []
    end
  end
end