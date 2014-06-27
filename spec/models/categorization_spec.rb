require "spec_helper"

describe Categorization do

  it { Factory.build(:categorization).should be_valid }

  it { should belong_to :application }
  it { should belong_to :category }

  it { should validate_presence_of :application }
  it { should validate_presence_of :category }
end
