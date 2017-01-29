require "spec_helper"

RSpec.describe Lru::Memcache::Demo do
  it "has a version number" do
    expect(Lru::Memcache::Demo::VERSION).not_to be nil
  end

  describe 'cache' do
    before(:each) do
      Cache = Lru::Memcache::Demo::Cache
      @cache = Cache.new
    end

    it 'retrieves stored values' do
      @cache.store 'x', 'y'
      expect(@cache.retrieve 'x').to eq('y')
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
  end
end
