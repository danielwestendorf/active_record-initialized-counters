# frozen_string_literal: true

RSpec.describe ActiveRecord::InitializedCounter::Model do
  let(:inactive_record_klass) do
    Class.new do
      def self.primary_key
        :id
      end

      def self.name
        "FakeRecord"
      end

      def self.initialize_callbacks
        @initialize_callbacks ||= []
      end

      def self.after_initialize(&blk)
        initialize_callbacks << blk
      end

      include ActiveRecord::InitializedCounter::Model

      attr_reader :id

      def initialize(id = nil)
        @id = id

        self.class.initialize_callbacks.each do |blk|
          instance_eval(&blk)
        end
      end

      def persisted?
        !@id.nil?
      end
    end
  end

  describe "counts initialization" do
    subject { ActiveRecord::InitializedCounter.counts }

    before do
      ActiveRecord::InitializedCounter.reset!
      stub_const("FakeRecord", inactive_record_klass)
      record
    end

    context "when persisted" do
      let(:record) { FakeRecord.new(42) }

      it { is_expected.to eq("FakeRecord" => {42 => 1}) }
    end

    context "when not persisted" do
      let(:record) { FakeRecord.new(nil) }

      it { is_expected.to eq({}) }
    end
  end
end
