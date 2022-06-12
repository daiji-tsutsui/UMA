require 'odds_analyzer'

RETURN_RATE = 0.8

RSpec.describe OddsAnalyzer do
  describe '#new' do
    it 'gives initial parameters' do
      obj = OddsAnalyzer.new
      expect(obj.a.class.to_s).to eq 'Probability'
      expect(obj.a).to            eq [1.0]
      expect(obj.b.class.to_s).to eq 'Positives'
      expect(obj.b).to            eq [1.0]
      expect(obj.t).to            eq nil
      expect(obj.blueprint).to    eq nil
      expect(obj.model).to        eq nil
      expect(obj.eps).to          eq 0.01
    end
  end

  describe '#strategy' do
    context 'for a biased odds' do
      before do
        @odds = [3.2, 3.2, 1.6]
        @t = Probability.new([0.3, 0.1, 0.5])
        @obj = OddsAnalyzer.new
      end

      it 'gives a probability' do
        b = 1.0
        res = @obj.strategy(@odds, @t, b)
        expect(res.class.to_s).to eq 'Probability'
        expect(res.size).to eq 3
      end
      it 'with larger b gives larger expected gain' do
        b1, b2 = 1.0, 2.0
        res1 = @obj.strategy(@odds, @t, b1)
        res2 = @obj.strategy(@odds, @t, b2)
        gain1 = @t.expectation(res1.map.with_index { |v, i| v * @odds[i] })
        gain2 = @t.expectation(res2.map.with_index { |v, i| v * @odds[i] })
        expect(gain1 < gain2).to be_truthy
      end
      it 'with larger b gives more peaky distribution' do
        b1, b2 = 1.0, 2.0
        res1 = @obj.strategy(@odds, @t, b1)
        res2 = @obj.strategy(@odds, @t, b2)
        expect(res1.max < res2.max).to be_truthy
      end
    end

    context 'for an unbiased odds' do
      before do
        @odds = [4.0, 2.0, 2.0]
        @t = Probability.new([0.2, 0.4, 0.4])
        @obj = OddsAnalyzer.new
      end

      it 'gives expected gain equal to return rate' do
        b1, b2 = 1.0, 2.0
        res1 = @obj.strategy(@odds, @t, b1)
        res2 = @obj.strategy(@odds, @t, b2)
        gain1 = @t.expectation(res1.map.with_index { |v, i| v * @odds[i] })
        gain2 = @t.expectation(res2.map.with_index { |v, i| v * @odds[i] })
        expect(gain1).to eq RETURN_RATE
        expect(gain2).to eq RETURN_RATE
      end
      it 'gives a uniform distribution for all b' do
        b1, b2 = 1.0, 2.0
        res1 = @obj.strategy(@odds, @t, b1)
        res2 = @obj.strategy(@odds, @t, b2)
        expect(res1[0]).to within(1e-6).of(res1[1])
        expect(res2[1]).to within(1e-6).of(res2[2])
      end
    end
  end

  describe '#forecast' do
    before do
      @odds_list = [
        [3.2,  3.2,  1.6],
        [4.0,  2.67, 1.6],
        [5.33, 2.67, 1.45],
      ]
      @obj = OddsAnalyzer.new
    end

    it 'gives a "true" probability @t' do
      @obj.forecast(@odds_list)
      expect(@obj.t.class.to_s).to eq 'Probability'
      expect(@obj.t[0] * @odds_list[0][0]).to eq RETURN_RATE
      expect(@obj.t[1] * @odds_list[0][1]).to eq RETURN_RATE
      expect(@obj.t[2] * @odds_list[0][2]).to eq RETURN_RATE
    end
    it 'gives a simulated series of odds' do
      @obj.forecast(@odds_list)
      expect(@obj.model.size).to eq 2
      expect(@obj.model[0].size).to eq 3
    end
    it 'gives a blueprint of strategies' do
      @obj.forecast(@odds_list)
      expect(@obj.blueprint.size).to eq 2
      expect(@obj.blueprint[0].size).to eq 3
    end
  end

  describe '#update_params' do
    before do
      @odds_list = [
        [3.2,  3.2,  1.6],
        [4.0,  2.67, 1.6],
        [5.33, 2.67, 1.45],
      ]
      @obj = OddsAnalyzer.new
    end

    it 'changes parameters #1' do
      @obj.forecast(@odds_list)
      old_a = @obj.a.clone
      old_b = @obj.b.clone
      old_t = @obj.t.clone
      @obj.update_params(@odds_list)
      expect(@obj.a).to_not eq old_a
      expect(@obj.b).to_not eq old_b
      expect(@obj.t).to_not eq old_t
    end
    it 'without forecasting causes exception' do
      expect{ @obj.update_params(@odds_list) }.to raise_error(NoMethodError)
    end
    it 'changes parameters #2' do
      old_a = @obj.a.clone
      old_b = @obj.b.clone
      old_t = @obj.t.clone
      @obj.update_params(@odds_list, with_forecast: true)
      expect(@obj.a).to_not eq old_a
      expect(@obj.b).to_not eq old_b
      expect(@obj.t).to_not eq old_t
    end
  end

  describe '#loss' do
    before do
      @odds_list = [
        [3.2,  3.2,  1.6],
        [4.0,  2.67, 1.6],
        [5.33, 2.67, 1.45],
      ]
      @obj = OddsAnalyzer.new
    end

    it 'gives an array of non-negative values #1' do
      @obj.forecast(@odds_list)
      res = @obj.loss(@odds_list)
      res.each do |val|
        expect(val >= 0).to be_truthy
      end
    end
    it 'without forecasting causes exception' do
      expect{ @obj.loss(@odds_list) }.to raise_error(NoMethodError)
    end
    it 'gives an array of non-negative values #2' do
      res = @obj.loss(@odds_list, with_forecast: true)
      res.each do |val|
        expect(val >= 0).to be_truthy
      end
    end
    it 'gives smaller values with updated parameters' do
      old_loss = @obj.loss(@odds_list, with_forecast: true)
      @obj.update_params(@odds_list)
      new_loss = @obj.loss(@odds_list, with_forecast: true)
      new_loss.each_with_index do |l, i|
        expect(l < old_loss[i]).to be_truthy
      end
    end
  end
end