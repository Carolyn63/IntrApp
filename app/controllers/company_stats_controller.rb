class CompanyStatsController < ApplicationController
	# Do before the controller is called 
	before_filter :require_user
	before_filter :find_company
	before_filter :only_owner


	def index
	end

	def cost_trend_app
		query = "SELECT DATE_FORMAT(p.transaction_date, '%Y-%m') AS ym, a.application_id, p.amount FROM payments p JOIN application_plans a ON p.plan_ids=a.id WHERE company_id=#{params[:id]} AND transaction_type in ('subscr_payment','onetime_payment') GROUP BY plan_ids, YEAR(transaction_date), MONTH(transaction_date) ORDER BY ym ASC"

logger.info "query: #{query}"

		result_set = ActiveRecord::Base.connection.execute(query) 
		@cost_trend_app_stats ||= Hash.new

		if !result_set.blank?
			result_set.each do |row|
				@cost_trend_app_stats[row[0] => row[1]] = row[2]
			end
		end

		#@cost_trend_app_stats = Hash[*ret]

		return @cost_trend_app_stats
	end

	def cost_trend_department
	end

	def top_apps_cost
	end

	def top_department_cost
	end

	def top_employee_cost
	end

	def app_seats_report
	end

	def cost_apps_user
	end

	def only_owner
		report_maflormed_data unless @company.admin == current_user
	end

	def find_company
		@company = Company.find_by_id params[:id]
		report_maflormed_data if @company.blank?
	end

end