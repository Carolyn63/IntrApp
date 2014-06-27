class Domain < ActiveRecord::Base

belongs_to :company

def self.create_domain fields
  unless fields.blank?
    @domain = Domain.new(fields)
    return true if @domain.save
  end
end

def self.destroy_domain company_id
  return true if Domain.find_by_company_id(company_id).delete
end

def self.update_domain fields
  return true if Domain.find_by_company_id(fields[:company_id]).update_attributes(fields)
end
end
