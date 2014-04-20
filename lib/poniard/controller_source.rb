module Poniard
  # Poniard source providing access to Rails controller features. It is always
  # available to poniard controllers added using
  # {Poniard::Controller::ClassMethods#provided_by}.
  class ControllerSource
    # A wrapper around the Rails response that provides a more OO-friendly
    # interface, specifically designed with isolated unit testing in mind.
    #
    # This class should not be explictly constructed by users. It is provided
    # in the response parameter provided by {ControllerSource}.
    class Response
      # @private
      attr_reader :controller, :injector

      # @private
      def initialize(controller, injector)
        @controller = controller
        @injector = injector
      end

      # Calls the given route method with arguments, then redirects to the
      # result. +_path+ is automatically appended so does not need to be
      # included in the path. +_url+ suffixes are handled correctly, in that
      # they are used as is without adding a +_path+ suffix. That is a little
      # magic, justified by +_path+ being what you want 90% of the time.
      #
      # @example
      #     def index(response)
      #       response.redirect_to :user, 1 # user_path(1)
      #     end
      def redirect_to(path, *args)
        unless path.to_s.ends_with?('_url')
          path = "#{path}_path"
        end

        controller.redirect_to(controller.send(path, *args))
      end

      # Redirect to the given action on the current controller.
      def redirect_to_action(action)
        controller.redirect_to action: action
      end

      # Render the view associated with given action with the given instance
      # variables.
      #
      # @param action[Symbol/String] name of the action
      # @param ivars[Hash] instance variables to be set for view rendering
      def render_action(action, ivars = {})
        render action: action, ivars: ivars
      end

      # Delegates directly to {ActionController::Head#head}.
      def head(*args)
        controller.head *args
      end

      # Delegates to `ActionController::Base#render`, with two exceptions if
      # the last argument is a hash:
      #
      # * +ivars+ is deleted from the hash and used to set instance variables
      #   that can then be accessed by any templates.
      # * +headers+ is deleted from the hash and used to set response headers.
      def render(*args)
        opts = args.last
        if opts.is_a?(Hash)
          ivars   = opts.delete(:ivars)
          headers = opts.delete(:headers)
        end
        ivars ||= {}
        headers ||= {}

        ivars.each do |name, val|
          controller.instance_variable_set("@#{name}", val)
        end

        headers.each do |name, val|
          controller.headers[name] = val
        end

        controller.render *args
      end

      # Renders default template for the current action. Equivalent to not call
      # any `render` method in a normal Rails controller. Unlike Rails, poniard
      # does not support empty method bodies.
      #
      # @param ivars[Hash] instance variables to be set for view rendering
      def default(ivars = {})
        ivars.each do |name, val|
          controller.instance_variable_set("@#{name}", val)
        end
      end

      # Object-oriented replacement for
      # {ActionController::MimeResponds#respond_to} method. The given class is
      # instantiated with the remaining arguments, and is expected to implement
      # a method named after each format it supports. The methods are called
      # via the injector.
      #
      # @example
      #     class MyController
      #       IndexResponse = Struct.new(:results) do
      #         def html(response)
      #           response.default results: results
      #         end
      #
      #         def json(response)
      #           response.render json: results
      #         end
      #       end
      #
      #       def index(response)
      #         response.respond_with IndexResponse, Things.all
      #       end
      #     end
      def respond_with(klass, *args)
        obj = klass.new(*args)
        format = controller.request.format.symbol
        if obj.respond_to?(format)
          injector.dispatch obj.method(format)
        end
      end

      # Delegates directly to {ActionController::DataStreaming#send_data}.
      def send_data(*args)
        controller.send_data(*args)
      end
    end

    # @private
    def initialize(controller)
      @controller = controller
    end

    # Provides direct access to +request+.
    def request;   @controller.request; end

    # Provides direct access to +params+.
    def params;    @controller.params; end

    # Provides direct access to +session+.
    def session;   @controller.session; end

    # Provides direct access to +flash+.
    def flash;     @controller.flash; end

    # Provides access to +flash.now+. It is useful, particularly when testing,
    # to treat this as a completely separate concept from +flash+.
    def now_flash; @controller.flash.now; end

    # Provides access to +render+ and friends abstracted behind {Response a
    # nice OO interface}.
    def response(injector)
      Response.new(@controller, injector)
    end

    # Provides direct access to +Rails.env+.
    def env
      Rails.env
    end

    # Provides direct access to +Rails.application.config+.
    def app_config
      Rails.application.config
    end
  end
end
