module RedisLogger
  class Railtie < Rails::Railtie

    initializer "redis_logger" do |app|
      app.config.middleware.swap("Rails::Rack::Logger", "RedisLogger::Rack::Logger")

      ActiveSupport.on_load(:action_controller) do
        require 'rack/logger.rb'
        include ActionController::RedisLogger
      end

    end

  end
end
