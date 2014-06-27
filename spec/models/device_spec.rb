require "spec_helper"

describe Device do
  it { Factory(:device).should be_valid }

  it { should have_many :applications }
  it { should have_many :employees }

  it { should validate_presence_of :name }

  it { should validate_presence_of :applications_count }
  it { should validate_presence_of :employees_count }
end
