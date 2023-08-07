# frozen_string_literal: true

RSpec.describe Activerecord::InitializedCounter do
  it "has a version number" do
    expect(Activerecord::InitializedCounter::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
