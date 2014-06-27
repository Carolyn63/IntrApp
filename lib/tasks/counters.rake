namespace :cached_counters do
  task :reset => :environment do
    [ApplicationType, Device, Category].each do |klass|
      klass.all.each do |d|
        klass.update_all "applications_count = #{ d.applications.length }", "id = #{ d.id }"
        puts "#{ klass.human_name } #{ d.name } has #{ d.applications_count } applications"
      end
    end

    Application.all.each do |app|
      Application.update_all "approved_companies_count = #{ app.active_companies.length }", "id = #{ app.id }"
      Application.update_all "departments_count = #{ app.departments.length }", "id = #{ app.id }"
      Application.update_all "approved_employees_count = #{ app.approved_employees.length }", "id = #{ app.id }"

      puts "#{ Application.human_name } #{ app.name } has #{ app.approved_companies_count } approved companies"
      puts "#{ Application.human_name } #{ app.name } has #{ app.departments_count } departments count"
      puts "#{ Application.human_name } #{ app.name } has #{ app.approved_employees_count } approved_employees count"
    end

    Device.all.each do |dev|
      Device.update_all "employees_count = #{ dev.employees.length }", "id = #{ dev.id }"
      puts "#{ Device.human_name } #{ dev.name } has #{ dev.employees_count } device count"
    end
  end
end
