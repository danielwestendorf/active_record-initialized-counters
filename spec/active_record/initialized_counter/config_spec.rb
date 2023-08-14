# frozen_string_literal: true

RSpec.describe ActiveRecord::InitializedCounter::Config do
  let(:instance) { described_class.new }

  describe "#ignored_classes" do
    subject { instance.ignored_classes }

    context "default value" do
      it { is_expected.to eq([]) }
    end

    context "returns memoized value" do
      before do
        instance.instance_variable_set(:@ignored_classes, ["foobar"])
      end

      it { is_expected.to eq(["foobar"]) }
    end
  end

  describe "#ignored_classes=" do
    subject { instance.instance_variable_get(:@ignored_classes) }

    let(:foo_klass) { Class.new }

    before do
      stub_const("Foo", foo_klass)

      instance.ignored_classes = ["Foo", "Array", "Baz"]
    end

    it { is_expected.to eq([Foo, Array]) }
  end
end
