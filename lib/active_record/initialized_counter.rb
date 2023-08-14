# frozen_string_literal: true

require_relative "initialized_counter/version"

module ActiveRecord
  module InitializedCounter
    autoload :ActiveJob, "active_record/initialized_counter/active_job"
    autoload :Middleware, "active_record/initialized_counter/middleware"
    autoload :Model, "active_record/initialized_counter/model"
    autoload :Config, "active_record/initialized_counter/config"

    class << self
      def configure
        yield config
      end

      def enabled?
        !disabled?
      end

      def disabled?
        config.disabled == true || Thread.current["active_record_initialized_counter_disabled"] == true
      end

      def disable!
        return config.disabled = true unless block_given?

        Thread.current["active_record_initialized_counter_disabled"] = true
        yield.tap do
          Thread.current["active_record_initialized_counter_disabled"] = nil
        end
      end

      def enable!
        config.disabled = Thread.current["active_record_initialized_counter_disabled"] = nil
      end

      def reporter
        config.reporter ||= proc { |values| puts values }
      end

      # Reporter should be a proc-like object that expects an array object
      # of the counts
      # config.reporter = proc { |hash_like_values| ... }
      def report
        reporter.call(counts) unless disabled?

        nil
      end

      def reset!
        Thread.current["active_record-initialized_counter_counts"] = nil
      end

      def counts
        Thread.current["active_record-initialized_counter_counts"] ||= {}
      end

      def count_and_report(&blk)
        reset!

        blk.call.tap { report }
      end

      def count(record)
        return if disabled?
        return if config.ignored_classes.any? { |klass| record.is_a?(klass) }
        return if record.class.primary_key.nil?

        primary_key = record.send record.class.primary_key

        counts[record.class.name] ||= Hash.new(0)
        counts[record.class.name][primary_key] += 1
      end

      private

      def config
        @config ||= Config.new
      end
    end
  end
end

require_relative "initialized_counter/railtie" if defined?(Rails::Railtie)
