module Poniard
  # Mixing this module into a Rails controller provides the poniard DSL to that
  # controller. To enable poniard on all controllers, mix this in to
  # `ApplicationController`.
  module Controller
    # @private
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    # Call the given method via the poniard injector. A `ControllerSource` is
    # provided as default, along with any sources passed to `provided_by`.
    def inject(method)
      injector = Injector.new [
        ControllerSource.new(self)
      ] + self.class.sources.map(&:new)
      injector.eager_dispatch self.class.provided_by.new.method(method)
    end

    # Class methods that are automatically added when `Controller` is included.
    module ClassMethods
      # For every non-inherited public instance method on the given class,
      # generates a method of the same name that calls it via the injector.
      #
      # If a `layout` method is present on the class, it is given special
      # treatment and set up so that it will be called using the Rails `layout`
      # DSL method.
      def provided_by(klass = nil, opts = {})
        if klass
          methods = klass.public_instance_methods(false)

          layout_method = methods.delete(:layout)

          methods.each do |m|
            class_eval <<-RUBY
              def #{m}
                inject :#{m}
              end
            RUBY
          end

          if layout_method
            layout :layout_for_controller

            class_eval <<-RUBY
              def layout_for_controller
                inject :layout
              end
            RUBY
          end

          @provided_by = klass
          @sources = opts.fetch(:sources, []).reverse
        else
          @provided_by
        end
      end

      # An array of sources to be used for all injected methods on the host
      # class. This is typically specified using the `sources` option to
      # `provided_by`, however you can override it for more complicated dynamic
      # behaviour.
      def sources
        @sources
      end
    end
  end
end
