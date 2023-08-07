# frozen_string_literal: true

require_relative "initialized_counter/version"

module ActiveRecord
  module InitializedCounter
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

      def reporter
        Thread.current["active_record-initialized_counter_reporter"] || proc { |values| puts values }
      end
    end
  end
end
