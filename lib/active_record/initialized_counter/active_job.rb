module ActiveRecord
  module InitializedCounter
    module ActiveJob
      def self.included(base)
        base.class_eval do
          around_perform do |_job, block|
            ActiveRecord::InitializedCounter.count_and_report { block.call }
          end
        end
      end
    end
  end
end
