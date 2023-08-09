# frozen_string_literal: true

require_relative "initialized_counter/version"

module ActiveRecord
  module InitializedCounter
    autoload :ActiveJob, "active_record/initialized_counter/active_job"
    autoload :Middleware, "active_record/initialized_counter/middleware"
    autoload :Model, "active_record/initialized_counter/model"

    class << self
      def config
        yield self
      end

      def enabled?
        !disabled?
      end

      def disabled?
        Thread.current["active_record-initialized_counter_disabled"] == true
      end

      def disable!
        Thread.current["active_record-initialized_counter_disabled"] = true
      end

      def enable!
        Thread.current["active_record-initialized_counter_disabled"] = nil
      end

      def reporter=(reporter)
        Thread.current["active_record-initialized_counter_reporter"] = reporter
      end

      # Reporter should be a proc-like object that expects an array object
      # of the counts
      def reporter
        Thread.current["active_record-initialized_counter_reporter"] ||= proc { |values| puts values }
      end

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

        primary_key = record.send record.class.primary_key

        counts[record.class.name] ||= Hash.new(0)
        counts[record.class.name][primary_key] += 1
      end
    end
  end
end

require_relative "initialized_counter/railtie" if defined?(Rails::Railtie)
