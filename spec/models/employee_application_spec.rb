require 'spec_helper'

describe EmployeeApplication do
  it { should belong_to :application }
  it { should belong_to :employee }

  it { should validate_presence_of :application }
  it { should validate_presence_of :employee }
  xit { should validate_uniqueness_of(:employee_id).scoped_to([:application_id]) }
end
