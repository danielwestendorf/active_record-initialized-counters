# frozen_string_literal: true

require "ostruct"

module ActiveRecord
  module InitializedCounter
    class Config < OpenStruct
      def ignored_classes
        @ignored_classes ||= []
      end

      # Pass an array of class names to ignore counting for
      # class names are constantized so we can take advantage
      # of inheritance to exclude individual classes and all
      # it's descendants
      def ignored_classes=(values)
        @ignored_classes = values.collect do |klass|
          Object.const_get(klass)
        rescue NameError
          nil
        end.compact
      end
    end
  end
end
