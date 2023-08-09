module ActiveRecord
  module InitializedCounter
    class Railtie < Rails::Railtie
      initializer "active_record.initialized_counter.configure_rails_initialization" do |app|
        app.middleware.use ActiveRecord::InitializedCounter::Middleware
        ::ActiveJob::Base.include(ActiveRecord::InitializedCounter::ActiveJob)

        ::ActiveRecord::Base.include(ActiveRecord::InitializedCounter::Model)
      end
    end
  end
end
