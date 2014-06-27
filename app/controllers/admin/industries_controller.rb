class Admin::IndustriesController < Admin::ResourcesController
  actions :all

  sortable_attributes :industry, :id, :applications_count
end

