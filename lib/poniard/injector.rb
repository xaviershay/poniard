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
      args = method.parameters.map {|_, name|
        source = sources_for(overrides).detect {|source|
          source.respond_to?(name)
        }

        if source
          dispatch(source.method(name), overrides)
        else
          UnknownInjectable.new(name)
        end
      }
      method.(*args)
    end

    def injector
      self
    end

    private

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
