<h1> Add IP PBX to Company and Employer<h1>

<%
company_id = 150
user_id = 343
application_id = 12

PortalIppbxController.new.add_company_ippbx(company_id, 5)
PortalIppbxController.new.add_user_ippbx(user_id,true)
employee = Employee.find_by_user_id(user_id)
application = Application.find_by_id(application_id)
request = employee.employee_applications.build(:application => application, :status => 'approved', :requested_at => Time.now, :assigned_by => '0')
request.save
%>