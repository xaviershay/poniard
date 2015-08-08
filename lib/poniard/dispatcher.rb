# Required to dynamically create classes bound to constants in a way that keeps
# Rails happy.
TopLevelBinding = binding

module Poniard

  # A custom Rails dispatcher that creates action controller wrappers for
  # poniard controllers on the fly. It is only triggered if a standard
  # controller cannot be found.
  class Dispatcher < ActionDispatch::Routing::RouteSet::Dispatcher
    def initialize(provider, *args)
      super *args
      @poniard_controller_provider = provider
    end

    def controller_reference(controller_param)
      super
    rescue NameError
      # This will have been set by super.
      default_name = @controller_class_names.fetch(controller_param)

      # Eval is the most robust way of creating a controller that everyone else
      # recognizes. Actually wrapping the poniard controller is delegated to
      # the `controller_provider`, to allow applications to define custom
      # behaviour.
      ruby = "class #{default_name} < ApplicationController; end"
      eval ruby, TopLevelBinding

      controller = Object.const_get(default_name)
      @poniard_controller_provider.decorate!(
        controller_param,
        controller
      )
      controller
    end

    def self.register!(app, provider = DefaultControllerProvider)
      app.routes.dispatcher_class =
        Poniard::DispatcherFactory.new(provider)
    end
  end

  DispatcherFactory = Struct.new(:provider) do
    def new(*args); Dispatcher.new(provider, *args) end
  end

  # Wraps an action controller around a poniard one. It is intended that users
  # subclass this to extend it with functionality specific to their app, such
  # as overriding `default_sources`.
  class DefaultControllerProvider
    attr_reader :controller_param, :singular_param, :controller

    def initialize(controller_param, controller)
      @controller       = controller
      @controller_param = controller_param
      @singular_param   = controller_param.singularize
    end

    def self.decorate!(*args); new(*args).decorate! end
    def decorate!
      controller.class_eval { include Poniard::Controller }
      controller.provided_by poniard_controller,
        sources: sources
    end

    protected

    def sources
      default_sources + specific_sources
    end

    def poniard_controller
      ActiveSupport::Dependencies.constantize(controller_name)
    end

    def default_sources
      []
    end

    def specific_sources
      begin
        [ActiveSupport::Dependencies.constantize(matching_source_name)]
      rescue NameError
        []
      end
    end

    def source_namespace; "Source" end
    def matching_source_name
      source_namespace + '::' + singular_param.camelize.gsub('::', '')
    end

    def controller_namespace; "Controller" end
    def controller_name
      controller_namespace + '::' + singular_param.camelize.gsub('::', '')
    end
  end
end
