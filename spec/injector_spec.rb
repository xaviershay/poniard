require 'poniard/injector'

describe Poniard::Injector do
  it 'yields a fail object when source is unknown' do
    called = false
    m = ->(unknown) {
      ->{
        unknown.bogus
      }.should raise_error(Poniard::UnknownParam)
      called = true
    }
    Poniard::Injector.new([]).dispatch(m)
    called.should be_true
  end
end
