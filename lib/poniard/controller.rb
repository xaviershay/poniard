module Poniard
  module Controller
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    def inject(method)
      injector = Injector.new [
        ControllerSource.new(self)
      ] + self.class.sources.map(&:new)
      injector.dispatch self.class.provided_by.new.method(method)
    end

    module ClassMethods
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

      def sources
        @sources
      end
    end
  end
end
