require 'spec_helper'

describe EmployeeDevice do
  it { should belong_to :device }
  it { should belong_to :employee }

  it { should validate_presence_of :device }
  it { should validate_presence_of :employee }
  xit { should validate_uniqueness_of(:employee_id).scoped_to([:device_id]) }
end
