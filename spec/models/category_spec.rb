require "spec_helper"

describe Category do
  it { Factory.build(:category).should be_valid }

  it { should have_many :applications }

  it { should validate_presence_of :name }

  it { should have_attribute :applications_count }

  it { should validate_presence_of :applications_count }
  it { should validate_numericality_of :applications_count }
end
