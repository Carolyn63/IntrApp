module Application::SearchOrFilterApplications
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def search_or_filter_applications(user, params = {})
      order_by = params[:order_by] == 'most_popular_first' ? "approved_employees_count desc" : "name asc"

      applications = if params[:search].blank?
        Application.available.
                    by_approved_company_id(params[:company_id]).
                    by_application_type_id(params[:application_type_id]).
                    by_category_ids(params[:categories_in]).
                    by_device_ids(params[:devices_in]).
                    by_approved_employee_ids(params[:employees_in]).
                    by_department_ids(params[:departments_in]).
                    paginate(:select => "DISTINCT applications.*", :per_page => 6, :page => params[:page], :order => order_by)
      else
        filters = {:status => Application::Status::ACTIVE}
        filters[:application_type_id] = params[:application_type_id] unless params[:application_type_id].blank?
        filters[:category_id] = params[:categories_in] unless params[:categories_in].blank?
        filters[:device_id] = params[:devices_in] unless params[:devices_in].blank?
        filters[:department_id] = params[:departments_in] unless params[:departments_in].blank?
        unless params[:company_id].blank?
          filters[:company_id] = params[:company_id]
          filters[:company_status] = Companification::Status::APPROVED.to_crc32
        end
        unless params[:employees_in].blank?
          filters[:employee_id] = params[:employees_in]
          filters[:employee_status] = EmployeeApplication::Status::APPROVED.to_crc32
        end
        Application.search(params[:search], {:with => filters, :page => params[:page], :order => order_by, :star => true})
      end
      applications
    end
  end
end
