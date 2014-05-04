module Poniard
  # A parameter pased dependency injector. Figures out which arguments to call
  # a method with based on the names of method's parameters. Multiple sources
  # can be provided to lookup parameter values. They are checked in reverse
  # order.
  #
  # The injector itself is always available to methods via the +injector+
  # parameter.
  #
  # @example
  #     def my_method(printer)
  #       printer.("hello!")
  #     end
  #
  #     Injector.new([{
  #       printer: ->(msg) { puts msg }
  #     }]).dispatch(method(:my_method))
  class Injector
    attr_reader :sources

    def initialize(sources = [])
      @sources = sources.map {|source|
        if source.is_a? Hash
          HashSource.new(source)
        else
          ObjectSource.new(self, source)
        end
      } + [HashSource.new(injector: self)]
    end

    # Call the given method with arguments. If a parameter is not provided by
    # any source, an {UnknownInjectable} instance is passed instead.
    def dispatch(method, overrides = {})
      dispatch_method(method, UnknownInjectable.method(:new), overrides)
    end

    # Same as {#dispatch}, except it raises an exception immediately if any
    # parameter is not provided by sources.
    def eager_dispatch(method, overrides = {})
      dispatch_method(method, ->(name) {
        ::Kernel.raise UnknownParam, name
      }, overrides)
    end

    private

    def dispatch_method(method, unknown_param_f, overrides = {})
      sources = sources_for(overrides)

      args = method.parameters.map {|_, name|
        source = sources.detect {|source|
          source.provides?(name)
        }

        if source
          source.dispatch(name, overrides)
        else
          unknown_param_f.(name)
        end
      }
      method.(*args)
    end

    def sources_for(overrides)
      [HashSource.new(overrides)] + sources
    end
  end

  # @private
  class HashSource
    def initialize(hash)
      @hash = hash
    end

    def provides?(name)
      @hash.has_key?(name)
    end

    def dispatch(name, _)
      @hash.fetch(name)
    end
  end

  # @private
  class ObjectSource
    def initialize(injector, object)
      @injector = injector
      @object   = object
    end

    def provides?(name)
      @object.respond_to?(name)
    end

    def dispatch(name, overrides)
      @injector.dispatch(@object.method(name), overrides)
    end
  end

  # Raised by {Injector#eager_dispatch} if a parameter is not provided by any
  # sources.
  class UnknownParam < RuntimeError; end

  # An object that will raise an exception if any method is called on it. This
  # is particularly useful in testing so that you only need to inject the
  # parameters that should actually be called during the test.
  class UnknownInjectable < BasicObject
    def initialize(name)
      @name = name
    end

    # @private
    def method_missing(*args)
      ::Kernel.raise UnknownParam,
        "Tried to call method on an uninjected param: #{@name}"
    end
  end
end
