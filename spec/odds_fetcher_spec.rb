# frozen_string_literal: true

require 'odds_fetcher'

RSpec.describe OddsFetcher do
  describe '#new' do
    it 'gives accessors' do
      obj = OddsFetcher.new(nil)
      expect(obj.odds).to eq []
    end
  end
end
