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
end
