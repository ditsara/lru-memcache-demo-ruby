require "spec_helper"

RSpec.describe Lru::Memcache::Demo do
  it "has a version number" do
    expect(Lru::Memcache::Demo::VERSION).not_to be nil
  end

  describe 'cache' do
    before(:each) do
      Cache ||= Lru::Memcache::Demo::Cache
      @mem_limit = 5
      @cache = Cache.new mem_limit: @mem_limit
    end

    it 'retrieves stored values' do
      @cache.store 'x', 'y'
      expect(@cache.retrieve 'x').to eq('y')
    end

    it 'returns nil for values not found' do
      expect(@cache.retrieve 'not_there').to be_nil
    end

    context 'with stored elements' do
      before(:each) do
        @cache.store 'first', 'data'
        @cache.store 'second', 'data'
        @cache.store 'third', 'data'
      end
      it 'pushes new vals to head' do
        expect(@cache.list.to_a).to eq(%w(third second first))
      end

      it 'promotes element order on retrieve' do
        @cache.retrieve 'second'
        expect(@cache.list.to_a).to eq(%w(second third first))
      end

      it 'leaves element order unchanged when retrieving head' do
        @cache.retrieve 'third'
        expect(@cache.list.to_a).to eq(%w(third second first))
      end

      it 'promotes element order when retrieving tail' do
        @cache.retrieve 'first'
        expect(@cache.list.to_a).to eq(%w(third first second))
      end
    end

    context 'size' do
      it 'increments size when element added' do
        expect { @cache.store 'k', 'v' }.to change { @cache.size }.from(0).to(1)
      end

      it 'does not change size when element replaced' do
        @cache.store 'k', 'v'
        expect { @cache.store 'k', 'v' }.not_to change { @cache.size }
      end

      it 'decrements size when element removed' do
        @cache.store 'k', 'v'
        expect { @cache.pop }.to change { @cache.size }.by(-1)
      end

      it 'drops elements if mem limit reached' do
        keys = @mem_limit.times.map { |i| "k-#{i}" }
        keys.each { |k| @cache.store k, 'val'}

        expect { @cache.store 'last', 'val' }.not_to change { @cache.size }

        list = (keys + ['last']).reverse[0..-2]
        expect(@cache.list.to_a).to eq(list)
      end
    end
  end
end
