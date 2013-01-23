module Poniard
  class ControllerSource
    Response = Struct.new(:controller, :injector) do
      def redirect_to(path, *args)
        unless path.to_s.ends_with?('_url')
          path = "#{path}_path"
        end

        controller.redirect_to(controller.send(path, *args))
      end

      def redirect_to_action(action)
        controller.redirect_to action: action
      end

      def render_action(action, ivars = {})
        render action: action, ivars: ivars
      end

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

      def default(ivars = {})
        ivars.each do |name, val|
          controller.instance_variable_set("@#{name}", val)
        end
      end

      def respond_with(klass, *args)
        obj = klass.new(*args)
        format = controller.request.format.symbol
        if obj.respond_to?(format)
          injector.dispatch obj.method(format)
        end
      end

      def send_data(*args)
        controller.send_data(*args)
      end
    end

    def initialize(controller)
      @controller = controller
    end

    def request;   @controller.request; end
    def params;    @controller.params; end
    def session;   @controller.session; end
    def flash;     @controller.flash; end
    def now_flash; @controller.flash.now; end

    def response(injector)
      Response.new(@controller, injector)
    end

    def env
      Rails.env
    end

    def app_config
      Rails.application.config
    end
  end
end
