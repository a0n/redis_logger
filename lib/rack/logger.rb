require 'active_support/core_ext/time/conversions'

module RedisLogger
  module Rack
    # Log the request started and flush all loggers after it.
    class Logger < ActiveSupport::LogSubscriber
    protected

      def before_dispatch(env)
        request = ActionDispatch::Request.new(env)
        path = request.filtered_path

        info "\n\nFucking #{request.request_method} \"#{path}\" " \
             "for #{request.ip} at #{Time.now.to_default_s}"
      end

    end
  end
end
