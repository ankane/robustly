require "safely/version"
require "errbase"
require "digest"

module Safely
  class << self
    attr_accessor :raise_envs, :tag, :report_exception_method, :throttle_counter
    attr_writer :env

    def report_exception(e, tag: nil)
      tag = Safely.tag if tag.nil?
      if tag && e.message
        e = e.dup # leave original exception unmodified
        message = e.message
        e.define_singleton_method(:message) do
          "[#{tag == true ? "safely" : tag}] #{message}"
        end
      end
      report_exception_method.call(e)
    end

    def env
      @env ||= ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
    end

    def throttled?(e, options)
      return false unless options
      key = "#{options[:key] || Digest::MD5.hexdigest([e.class.name, e.message, e.backtrace.join("\n")].join("/"))}/#{(Time.now.to_i / options[:period]) * options[:period]}"
      throttle_counter.clear if throttle_counter.size > 1000 # prevent from growing indefinitely
      (throttle_counter[key] += 1) > options[:limit]
    end
  end

  DEFAULT_EXCEPTION_METHOD = proc do |e|
    Errbase.report(e)
  end

  self.tag = true
  self.report_exception_method = DEFAULT_EXCEPTION_METHOD
  self.raise_envs = %w(development test)
  # not thread-safe, but we don't need to be exact
  self.throttle_counter = Hash.new(0)

  module Methods
    def safely(tag: nil, sample: nil, except: nil, only: nil, silence: nil, throttle: false, default: nil)
      yield
    rescue *Array(only || StandardError) => e
      raise e if Array(except).any? { |c| e.is_a?(c) }
      raise e if Safely.raise_envs.include?(Safely.env)
      if sample ? rand < 1.0 / sample : true
        begin
          unless Array(silence).any? { |c| e.is_a?(c) } || Safely.throttled?(e, throttle)
            Safely.report_exception(e, tag: tag)
          end
        rescue => e2
          $stderr.puts "FAIL-SAFE #{e2.class.name}: #{e2.message}"
        end
      end
      default
    end
    alias_method :yolo, :safely
  end
  extend Methods

  module ClassMethods
    def safely_method(method_id, options = {})
      original_method_id = :"_safely_method_#{method_id}"
      alias_method original_method_id, method_id

      define_method method_id do |*args, &blk|
        safely(options) do
          send(original_method_id, *args, &blk)
        end
      end

      if private_instance_methods.include?(original_method_id)
        private method_id
      elsif protected_instance_methods.include?(original_method_id)
        protected method_id
      end
    end
  end
end
