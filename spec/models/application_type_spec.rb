require "spec_helper"

describe ApplicationType do
  it { Factory.build(:application_type).should be_valid }

  it { should have_many :applications }

  it { should validate_presence_of :name }

  it { should have_attribute :applications_count }
end
