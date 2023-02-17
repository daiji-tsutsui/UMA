# frozen_string_literal: true

require 'positives'

RSpec.describe Positives do
  describe '#new' do
    it 'with no args' do
      vect = Positives.new
      expect(vect).to eq [1.0]
    end

    it 'with an arg' do
      arg = [0.1, 0.2, 0.3]
      vect = Positives.new(arg)
      expect(vect).to eq arg
    end
  end

  describe '#move!' do
    before do
      @ini = [1.0, 2.0, 3.0]
      @src = Positives.new(@ini)
    end

    it 'moves self in the meaning of m-parallel transportation' do
      v = [1.0, 1.0]
      @src.move!(v)
      expect(@src).to eq [1.0, 2.0 + 1.0, 3.0 + 1.0]
    end
    it 'does not move self when v is zero' do
      v = [0.0, 0.0]
      @src.move!(v)
      expect(@src).to eq @ini
    end
  end

  describe '#move_with_natural_grad!' do
    before do
      @ini = [1.0, 2.0, 3.0]
      @src = Positives.new(@ini)
    end

    it 'moves self in the direction of natural gradient' do
      v = [1.0, 2.0]
      @src.move_with_natural_grad!(v)
      expect(@src).to eq [1.0, 2.0 * (1.0 + v[0]), 3.0 * (1.0 + v[1])]
    end
    it 'does not move self when v is 0' do
      v = [0.0, 0.0]
      @src.move_with_natural_grad!(v)
      expect(@src).to eq @ini
    end
  end

  describe '#extend_to!' do
    before do
      @ini = [1.0, 2.0, 3.0]
      @src = Positives.new(@ini)
    end

    it 'extends self simply by adding extra 1.0' do
      @src.extend_to!(5)
      expect(@src).to eq [1.0, 2.0, 3.0, 1.0, 1.0]
    end
    it 'raises exception when trg_size is less than self size' do
      expect { @src.extend_to!(2) }.to raise_error(ArgumentError)
    end
  end
end
