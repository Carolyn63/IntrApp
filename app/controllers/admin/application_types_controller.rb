class Admin::ApplicationTypesController < Admin::ResourcesController
  actions :all

  sortable_attributes :name, :id, :applications_count, :description
end
