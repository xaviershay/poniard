require 'ostruct'

module Poniard
  class Injector
    attr_reader :sources

    def initialize(sources = [])
      @sources = sources.map {|source|
        if source.is_a? Hash
          OpenStruct.new(source)
        else
          source
        end
      }+ [self]
    end

    def dispatch(method, overrides = {})
      dispatch_method(method, UnknownInjectable.method(:new), overrides)
    end

    def eager_dispatch(method, overrides = {})
      dispatch_method(method, ->(name) {
        ::Kernel.raise UnknownParam, name
      }, overrides)
    end

    def injector
      self
    end

    private

    def dispatch_method(method, unknown_param_f, overrides = {})
      args = method.parameters.map {|_, name|
        source = sources_for(overrides).detect {|source|
          source.respond_to?(name)
        }

        if source
          dispatch(source.method(name), overrides)
        else
          unknown_param_f.(name)
        end
      }
      method.(*args)
    end

    def sources_for(overrides)
      [OpenStruct.new(overrides)] + sources
    end
  end

  class UnknownParam < RuntimeError; end

  class UnknownInjectable < BasicObject
    def initialize(name)
      @name = name
    end

    def method_missing(*args)
      ::Kernel.raise UnknownParam,
        "Tried to call method on an uninjected param: #{@name}"
    end
  end
end
