require 'action_controller/railtie'
require 'rspec/rails'

require 'poniard'

Rails.backtrace_cleaner.remove_silencers!
class PoniardApp < Rails::Application
  config.secret_token = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
  config.session_store :cookie_store, :key => '_myproject_session'
  config.active_support.deprecation = :log
  config.eager_load = false
  config.root = File.dirname(__FILE__)
end
PoniardApp.initialize!

class ApplicationController < ActionController::Base
  before_filter :prepend_view_paths

  def prepend_view_paths
    prepend_view_path File.expand_path("../views", __FILE__)
  end

  def admin_path(page)
    "/admin/#{page}"
  end

  def admin_url(page)
    "http://foo/admin/#{page}"
  end
end

RSpec.configure do |config|
  def poniard_controller(&block)
    controller(ApplicationController) do
      include Poniard::Controller

      provided_by(Class.new(&block))
    end
  end
end
