require 'benchmark'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'poniard/injector'

N = 10000

Benchmark.benchmark("", 15) do |bm|
  injector = Poniard::Injector.new([
    {a: Object.new},
    {b: Object.new},
    {c: Object.new}
  ])
  m = ->(a, b, c, d) { }

  bm.report("#dispatch") do
    N.times do
      injector.dispatch(m, d: Object.new)
    end
  end

  bm.report("#eager_dispatch") do
    N.times do
      injector.dispatch(m, d: Object.new)
    end
  end
end
