# frozen_string_literal: true

RSpec.describe ActiveRecord::InitializedCounter::ActiveJob do
  let(:inactive_record_klass) do
    Class.new do
      def self.primary_key
        :id
      end

      def self.name
        "FakeRecord"
      end

      def initialize(*args)
        super.tap do
          ActiveRecord::InitializedCounter.count(self)
        end
      end

      def id
        42
      end
    end
  end

  let(:klass) do
    Class.new do
      def self.around_callbacks
        @around_callbacks ||= []
      end

      def self.around_perform(&blk)
        around_callbacks << blk
      end

      def self.perform_now
        instance = new

        around_callbacks.each do |blk|
          blk.call("_jobwhatever", proc { instance.perform })
        end
      end

      include ActiveRecord::InitializedCounter::ActiveJob

      def perform
        FakeRecord.new
      end
    end
  end

  it "counts and reports" do
    stub_const("FakeRecord", inactive_record_klass)

    expect(ActiveRecord::InitializedCounter).to receive(:count_and_report)
      .and_call_original

    klass.perform_now
    expect(ActiveRecord::InitializedCounter.counts).to eq("FakeRecord" => {42 => 1})
  end
end
