class Admin::DevicesController < Admin::ResourcesController
  actions :all

  sortable_attributes :name, :id, :applications_count, :employees_count, :description
end

