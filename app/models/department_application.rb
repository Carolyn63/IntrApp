class DepartmentApplication < ActiveRecord::Base
  belongs_to :application, :counter_cache => :departments_count
  belongs_to :department

  validates_presence_of :application
  validates_presence_of :department
  validates_uniqueness_of :department_id, :scope => [:application_id]

  after_save :assign_application_to_employees
  after_destroy :unassign_application_from_employees

  protected

  def assign_application_to_employees
    transaction do
      department.employees.each do |employee|
        employee_application = application.employee_applications.pending_or_rejected.find_by_employee_id(employee.id)
        if employee_application.present?
          employee_application.update_attribute(:status, EmployeeApplication::Status::APPROVED)
        else
          application.employee_applications.create(:employee => employee)
        end
      end
    end
  end

  def unassign_application_from_employees
    EmployeeApplication.destroy_all(["application_id = ? AND employee_id IN(?)", application.id, department.employees.map(&:id)])
  end
end
