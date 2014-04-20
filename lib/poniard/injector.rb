require 'ostruct'

module Poniard
  # A parameter pased dependency injector. Figures out which arguments to call
  # a method with based on the names of method's parameters. Multiple sources
  # can be provided to lookup parameter values. They are checked in reverse
  # order.
  #
  # For complex dispatches, the injector is available to methods via the
  # +injector+ parameter.
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
          OpenStruct.new(source)
        else
          source
        end
      } + [OpenStruct.new(injector: self)]
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
