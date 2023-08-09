# frozen_string_literal: true

RSpec.describe ActiveRecord::InitializedCounter::Middleware do
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

  let(:app) {
    proc { |env|
      FakeRecord.new
      [200, {}, "hey!"]
    }
  }

  it "counts and reports" do
    stub_const("FakeRecord", inactive_record_klass)

    expect(ActiveRecord::InitializedCounter).to receive(:count_and_report)
      .and_call_original

    expect(described_class.new(app).call({})).to eq([200, {}, "hey!"])
    expect(ActiveRecord::InitializedCounter.counts).to eq("FakeRecord" => {42 => 1})
  end
end
