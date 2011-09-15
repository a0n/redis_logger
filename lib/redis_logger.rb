require 'redis'
require 'json'

#
# redis_logger
# http://github.com/masonoise/redis_logger
#
# Enable logging into redis database, with support for grouping log entries into one or more
# groups.
#
# Log entries are stored in redis using keys of the form: log:<timestamp> with timestamp being
# a longint representation of the time. Log entries are then also added to a set associated
# with the log level, and then with any other sets specified in a list of "log groups".
#
# A set is maintained with the list of all of the groups: "logger:sets". Each group is
# represented by a set called "logger:set:<name>" where name is the group name.
#
class RedisLogger
  
  module Severity
    DEBUG   = 0
    INFO    = 1
    WARN    = 2
    ERROR   = 3
    FATAL   = 4
    UNKNOWN = 5
  end
  include Severity
  
  
  def initialize(level = DEBUG)
    @level         = level
    @redis         = self.class.redis
  end

  def self.redis=(server)
    host, port, db = server.split(':')
    @redis = Redis.new(:host => host, :port => port, :thread_safe => true, :db => db)
  end

  def self.redis
    return @redis if @redis
    self.redis = 'localhost:6379'
    self.redis
  end

   Severity.constants.each do |severity|
      class_eval <<-EOT, __FILE__, __LINE__ + 1
        def #{severity.downcase}(message = nil, progname = nil, &block) # def debug(message = nil, progname = nil, &block)
          add(#{severity}, message, progname, &block)                   #   add(DEBUG, message, progname, &block)
        end                                                             # end

        def #{severity.downcase}?                                       # def debug?
          #{severity} >= @level                                         #   DEBUG >= @level
        end                                                             # end
      EOT
    end
    
  def add(severity, message = nil, progname = nil, &block)
     return if @level > severity
     if (message == nil)
       message = ((block && block.call) || progname).to_s
     else
      
     end
     # If a newline is necessary then create a new message ending with a newline.
     # Ensures that the original message is not mutated.
     tstamp = Time.now.to_i
     
     level = {
             0 => "DEBUG",
             1 => "INFO",
             2 => "WARN",
             3 => "ERROR",
             4 => "FATAL"
           }[severity] || "U"
     
     log_entry = {}
     log_entry["message"] = message  
     log_entry["timestamp"] = tstamp
     log_entry["level"] = level
     # Add entry to the proper log-level set, and desired group sets if any
     #if tags == nil
     #  tags = []
     #elsif tags.is_a?(String)
     #  tags = tags.to_a
     #end

     # TODO: Need to add unique id to timestamp to prevent multiple servers from causing collisions
     #log_entry["tags"] = tags
     redis = @redis
     #redis.set "log:#{tstamp}", log_entry.to_json
     #redis.sadd "logger:level:#{level}", tstamp

     # hmset() seems to be broken so skip it for now. Could pipeline the above commands.
     #redis.hmset tstamp, *(log_entry.to_a)

     # TODO: Shouldn't need to add the level every time; could do it once at startup?
     redis.publish "ss:channels", {:event => "newLog" ,:params => log_entry, :destinations => level.to_a}.to_json

     #tags.each do |tag|
     #  redis.sadd "logger:tags", tag
     #  redis.sadd "logger:tag:#{tag}", tstamp
     #end
  end  


  #
  # Provide standard methods for various log levels. Each just calls the private
  # add_entry() method passing in its level name to use as the group name.
  #
  # For each, the log_entry is a Hash of items to include in the log, and sets is
  # either a string or an array of strings, which are the groups into which the
  # entry will be added (in addition to the standard log level group).
  #

end
