module ActiveRecord
  module InitializedCounter
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        ActiveRecord::InitializedCounter.count_and_report { @app.call(env) }
      end
    end
  end
end
