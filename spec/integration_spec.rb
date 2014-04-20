require 'integration_helper'

describe Poniard::ControllerSource, type: :controller do
  describe 'Response' do
    context '#default' do
      render_views

      poniard_controller do
        def index(response)
          response.default message: "implicit"
        end
      end

      it 'renders template matching method name with instance variables' do
        get :index
        expect(response.body).to match(/Message: implicit/)
      end
    end

    context '#render' do
      render_views

      poniard_controller do
        def index(response)
          response.render action: 'index',
            headers: {'Content-Type' => 'text/plain'},
            ivars: {message: 'explicit'}
        end
      end

      it 'renders explicit template with instance variables' do
        get :index
        expect(response.body).to match(/Message: explicit/)
      end

      it 'can set headers' do
        get :index
        expect(response.headers['Content-Type']).to eq('text/plain')
      end
    end

    context '#render_action' do
      render_views

      poniard_controller do
        def index(response)
          response.render_action 'index', message: 'explicit'
        end
      end

      it 'renders explicit template with instance variables' do
        get :index
        expect(response.body).to match(/Message: explicit/)
      end
    end

    describe '#head' do
      poniard_controller do
        def index(response)
          response.head 422
        end
      end

      it 'sets response code' do
        get :index
        expect(response.status).to eq(422)
      end
    end

    describe '#redirect_to' do
      # See fake admin_* route methods in integration_helper.rb

      context 'path' do
        poniard_controller do
          def index(response)
            response.redirect_to :admin, :secret
          end
        end

        it 'redirects' do
          get :index
          expect(response).to redirect_to("/admin/secret")
        end
      end

      context 'url' do
        poniard_controller do
          def index(response)
            response.redirect_to :admin_url, :secret
          end
        end

        it 'redirects' do
          get :index
          expect(response).to redirect_to("http://foo/admin/secret")
        end
      end

      context 'arbitrary' do
        poniard_controller do
          def index(response)
            response.redirect_to '/some_path'
          end
        end

        it 'redirects' do
          get :index
          expect(response).to redirect_to("/some_path")
        end
      end
    end

    context '#redirect_to_action' do
      poniard_controller do
        def index(response)
          response.redirect_to_action :new
        end

        def new
        end
      end

      it 'redirects' do
        pending "Not sure correct rspec-rails scaffolding to make this work"
        get :index
        expect(response).to redirect_to(:new)
      end
    end

    describe '#send_data' do
      poniard_controller do
        def index(response)
          response.send_data "data", type: "text/plain"
        end
      end

      it 'sends body' do
        get :index
        expect(response.body).to eq("data")
      end

      it 'sets headers' do
        get :index
        expect(response.headers['Content-Type']).to eq("text/plain")
      end
    end

    describe '#respond_with' do
      render_views

      poniard_controller do
        def index(response)
          responder = Class.new do
            def initialize(body)
              @body = body
            end

            def html(response); response.render text: "<b>#{@body}</b>" end
            def text(response); response.render text: @body end
          end

          response.respond_with responder, "body"
        end
      end

      it 'responds with html' do
        get :index
        expect(response.body).to eq("<b>body</b>")
      end

      it 'responds with text' do
        get :index, format: :text
        expect(response.body).to eq("body")
      end

      it 'handles unknown format' do
        get :index, format: :json
        expect(response.status).to eq(406)
      end
    end
  end

  context 'request source' do
    poniard_controller do
      def index(response, request)
        response.render text: request.path
      end
    end

    it 'provides access to raw rails request' do
      get :index
      expect(response.body).to eq("/anonymous")
    end
  end

  context 'params source' do
    poniard_controller do
      def index(response, params)
        response.render text: params[:q]
      end
    end

    it 'provides access to raw rails params' do
      get :index, q: 'query'
      expect(response.body).to eq("query")
    end
  end

  context 'session source' do
    poniard_controller do
      def index(response, session)
        response.render text: session[:user_id]
      end
    end

    it 'provides access to raw rails session' do
      get :index, {}, {user_id: '1'}
      expect(response.body).to eq("1")
    end
  end

  context 'flash source' do
    poniard_controller do
      def index(response, flash)
        flash[:message] = "FLASH"
        response.render text: ""
      end
    end

    it 'provides access to raw rails flash' do
      get :index
      expect(flash[:message]).to eq("FLASH")
    end
  end

  context 'flash now source' do
    poniard_controller do
      def index(response, now_flash)
        now_flash[:message] = "FLASH"
        response.render text: ""
      end
    end

    it 'provides access to raw rails flash' do
      get :index
      expect(flash[:message]).to eq("FLASH")
    end
  end

  context 'env source' do
    poniard_controller do
      def index(response, env)
        response.render text: env
      end
    end

    it 'provides access to current environment' do
      get :index
      expect(response.body).to eq("test")
    end
  end

  context 'config source' do
    poniard_controller do
      def index(response, app_config)
        response.render text: app_config.secret_token
      end
    end

    it 'provides access to current config' do
      get :index
      expect(response.body).to eq(PoniardApp.config.secret_token)
    end
  end

  context 'with layout' do
    render_views

    poniard_controller do
      def layout
        'admin'
      end

      def index(response, app_config)
        response.render text: "secret", layout: true
      end
    end

    it 'uses the provided layout' do
      get :index
      expect(response.body).to match(/ADMIN: secret/)
    end
  end
end
