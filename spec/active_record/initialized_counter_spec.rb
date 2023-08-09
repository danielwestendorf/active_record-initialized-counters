# frozen_string_literal: true

RSpec.describe ActiveRecord::InitializedCounter do
  describe ".config" do
    it "yields" do
      described_class.config do |config|
        expect(config).to eq(described_class)
      end
    end
  end

  describe ".disabled?" do
    subject { described_class.disabled? }

    context "set to true" do
      before do
        Thread.current["active_record-initialized_counter_disabled"] = true
      end

      it { is_expected.to eq(true) }
    end

    context "set to not true" do
      before do
        Thread.current["active_record-initialized_counter_disabled"] = "true"
      end

      it { is_expected.to eq(false) }
    end
  end

  describe ".enabled?" do
    subject { described_class.enabled? }

    context "is disabled" do
      before do
        allow(described_class).to receive(:disabled?)
          .and_return(true)
      end

      it { is_expected.to eq(false) }
    end

    context "is not disabled" do
      before do
        allow(described_class).to receive(:disabled?)
          .and_return(false)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe ".reporter=" do
    subject { described_class.reporter = "foobar" }

    it "sets the reporter" do
      expect { subject }.to change { Thread.current["active_record-initialized_counter_reporter"] }.to "foobar"
    end
  end

  describe ".reporter" do
    subject { described_class.reporter }

    around do |ex|
      described_class.reporter = reporter
      ex.run
      described_class.reporter = nil
    end

    context "default" do
      let(:reporter) { nil }

      it { is_expected.to be_kind_of(Proc) }
    end

    context "custom" do
      let(:reporter) { "foobar" }

      it { is_expected.to eq("foobar") }
    end
  end

  describe ".counts" do
    subject { described_class.counts }

    around do |ex|
      Thread.current["active_record-initialized_counter_counts"] = counts
      ex.run
      Thread.current["active_record-initialized_counter_counts"] = nil
    end

    context "default" do
      let(:counts) { nil }

      it { is_expected.to eq({}) }
    end

    context "custom" do
      let(:counts) { "foobar" }

      it { is_expected.to eq("foobar") }
    end
  end

  describe ".reset!" do
    subject { described_class.reset! }

    before do
      Thread.current["active_record-initialized_counter_counts"] = "foobar"
    end

    it "unsets the counts thread local variable" do
      expect { subject }.to change { Thread.current["active_record-initialized_counter_counts"] }
    end
  end

  describe ".report" do
    around do |ex|
      described_class.disable! if disabled?

      ex.run

      described_class.enable!
    end

    context "when disabled" do
      let(:disabled?) { true }

      it "does not call the reporter" do
        expect(described_class.reporter).not_to receive(:call)

        expect(described_class.report).to eq(nil)
      end
    end

    context "when enabled" do
      let(:disabled?) { false }

      it "calls the reporter" do
        expect(described_class.reporter).to receive(:call)
          .with(described_class.counts)

        expect(described_class.report).to eq(nil)
      end
    end
  end

  describe ".count_and_report" do
    it "resets, calls the passed block, and then reports" do
      blk = proc { 1 }

      expect(described_class).to receive(:reset!)
      expect(blk).to receive(:call)
        .and_call_original
      expect(described_class).to receive(:report)

      expect(described_class.count_and_report(&blk)).to eq(1)
    end
  end

  describe ".count" do
    let(:klass) do
      Class.new do
        attr_accessor :id

        def initialize(id)
          @id = id
        end

        def self.name
          "Klass"
        end

        def self.primary_key
          :id
        end
      end
    end

    context "disabled" do
      around do |ex|
        described_class.disable!
        ex.run
        described_class.enable!
      end

      it "does not count" do
        expect(described_class.count(klass.new(42))).to eq(nil)

        expect(described_class.counts).to eq({})
      end
    end

    context "enabled" do
      it "counts each occurrence" do
        expect(described_class.count(klass.new(42))).to eq(1)
        expect(described_class.count(klass.new(43))).to eq(1)
        expect(described_class.count(klass.new(42))).to eq(2)

        expect(described_class.counts).to eq(
          "Klass" => {
            42 => 2,
            43 => 1
          }
        )
      end
    end
  end
end
