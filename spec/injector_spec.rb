require 'spec_helper'

require 'poniard/injector'

describe Poniard::Injector do
  let(:thing) { Object.new }

  it 'calls a lambda' do
    called = false
    described_class.new([]).dispatch -> { called = true }
    expect(called).to eq(true)
  end

  it 'calls a method' do
    object = Class.new do
      def a_number
        12345
      end
    end.new

    actual = described_class.new([]).dispatch(object.method(:a_number))

    expect(actual).to eq(12345)
  end

  it 'calls a method with a parameter provided by a source' do
    called = false
    described_class.new([
      thing: thing
    ]).dispatch ->(thing) { called = thing }
    expect(called).to eq(thing)
  end

  it 'recursively injects sources' do
    two_source = Class.new do
      def two_things(thing)
        [thing, thing]
      end
    end.new

    called = false
    described_class.new([
      {thing: thing},
      two_source
    ]).dispatch ->(two_things) { called = two_things }
    expect(called).to eq([thing, thing])
  end

  it 'uses the first source that provides a parameter' do
    called = false
    described_class.new([
      {thing: thing},
      {thing: nil}
    ]).dispatch ->(thing) { called = thing }
    expect(called).to eq(thing)
  end

  it 'allows sources to be overriden at dispatch' do
    called = false
    described_class.new([
      {thing: nil}
    ]).dispatch ->(thing) { called = thing }, thing: thing
    expect(called).to eq(thing)
  end

  it 'provides itself as a source' do
    called = false
    injector = described_class.new
    injector.dispatch ->(injector) { called = injector }
    expect(called).to eq(injector)
  end

  it 'allows nil values in hash sources' do
    value = nil
    injector = described_class.new
    injector.dispatch ->(x) { value = x.nil? }, x: nil
    expect(value).to eq(true)
  end

  it 'yields a fail object when source is unknown' do
    called = false
    m = ->(unknown) {
      expect{
        unknown.bogus
      }.to raise_error(
        Poniard::UnknownParam,
        "Tried to call method on an uninjected param: unknown"
      )
      called = true
    }
    described_class.new.dispatch(m)
    expect(called).to eq(true)
  end

  describe '#eager_dispatch' do
    it 'raises when source is unknown' do
      m = ->(unknown) {}
      expect {
        described_class.new.eager_dispatch(m)
      }.to raise_error(Poniard::UnknownParam, "unknown")
    end
  end
end
