module ActiveRecord
  module InitializedCounter
    module Model
      def self.included(base)
        base.class_eval do
          after_initialize do
            ActiveRecord::InitializedCounter.count(self) if persisted?
          end
        end
      end
    end
  end
end
