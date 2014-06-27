require 'rubygems'
require 'linkedin'
class Admin::Scripts::RetrievelinkedinController < Admin::ResourcesController

	def index
	end

	def retrieve_companies
=begin
		date_diff = (Date.today  -  "2012-09-21".to_date).to_i

		ids_start = 1000000 + 500 * date_diff + 1
		ids_end = ids_start + 499

		client = LinkedIn::Client.new(property(:linkedin_api_key), property(:linkedin_secret_key))
		client.authorize_from_access(property(:linkedin_oauth_user_token), property(:linkedin_oauth_user_secret))

		companies = Array.new

	 #for i in 1301..1491# Linked company IDs are starting from 1000.
	 # we've done up to 1008500 on 20121007
		for i in ids_start..ids_end
			begin
				company =client.company(:id => i.to_s, :fields => %w(id name universal-name website-url industries logo-url employee-count-range locations:(address:(street1 city state postal-code country-code) contact-info:(phone1)))).to_hash

				unless company.blank?
					code, emplyee_count, employee_size, address, city, state, zipcode, phone, country = ""

					if company["industries"].present? and company["industries"]["total"].to_i > 0
						code = company["industries"]["all"][0].code
					end

					if (company["employee_count_range"].present?)
						employee_count = company["employee_count_range"]["code"]
						employee_size = company["employee_count_range"]["name"]
					end

					if (employee_count == "A" or employee_count == "B" or employee_count == "C" or employee_count == "D")
						if company["locations"]["total"].to_i>0
							address = company["locations"]["all"][0].address.street1
							city =company["locations"]["all"][0].address.city 
							state =company["locations"]["all"][0].address.state
							zipcode = company["locations"]["all"][0].address.postal_code
							phone = company["locations"]["all"][0].contact_info.phone1
							unless (company["locations"]["all"][0].address.country_code.blank?)
								country = from_country_code(company["locations"]["all"][0].address.country_code.upcase)
								#company_name = company["name"]
								#country_code = company["locations"]["all"][0].address.country_code.upcase
								#logger.info("company name: #{company_name} country code: #{country_code}")
							end
						end

						field_company = {:name => company["name"], :address => address, :city => city, :state => state, :zipcode => zipcode, :phone => phone, :country => country, :industry =>code, :created_from => "linkedin" , :size => employee_size, :company_id => company["id"]}

						logger.info("Company ID linkedin_companies insertion #{field_company[:company_id].to_s}")

						cquery1 = "insert into linkedin_companies (created_at,linkedin,"
						cquery2 = ") values ('#{Time.new.strftime("%Y-%m-%d %H:%M:%S")}','#{field_company[:company_id]}',"
						field_company.each do |key, value| 
							unless key.blank?
								unless key.to_s.eql?("company_id")
									cquery1+= "#{key},"
									cquery2+= "'#{addslash(value.to_s)}',"
								end
							end
						end
						cquery = cquery1.chop + cquery2.chop + ")"
						logger.info(cquery)
						ActiveRecord::Base.connection.execute(cquery)

					end # of of if size filter
				end # end of unless
			rescue
				logger.info("limit exceeded")
			end # end of begin
		end # end of for
		logger.info("**********************Comapnies End*******************\n")
		flash[:notice] = "Retrieve LinkedIn Companies successfully"
		redirect_to :action => :index
=end
	end


	def retrieve_users
=begin
		client = LinkedIn::Client.new(property(:linkedin_api_key), property(:linkedin_secret_key))
		client.authorize_from_access(property(:linkedin_oauth_user_token), property(:linkedin_oauth_user_secret))
		for i in  1000381 .. 1000780
			company = LinkedinCompany.find_by_linkedin(i)
			unless company.blank?
				begin
					user = client.search(:keywords => "#{company.name} + " " +Founder", :fields => %w(people:(id first-name last-name))).to_hash
					logger.info(user)
					if (user["people"]["total"].to_i>0)  
						user = user["people"]["all"][0]
						fields = {:firstname=> user.first_name, :lastname => user.last_name, :linkedin => user.id, :login => company.linkedin}
						uquery1 = "insert into linkedin_users (created_at,"
						uquery2 = ") values ('#{Time.new.strftime("%Y-%m-%d %H:%M:%S")}',"
						fields.each do |key, value| 
							unless key.blank?
								uquery1+= "#{key},"
								uquery2 += "'#{value.to_s}',"
							end
						end
						uquery = uquery1.chop + uquery2.chop + ")"
						logger.info(uquery)
						ActiveRecord::Base.connection.execute(uquery)

					end #end of user retrieval
				rescue
					logger.info("User retrival Failed...")
				end
			end
		end
		flash[:notice] = "Retrieve LinkedIn Users successfully"
		redirect_to :action => :index
=end
	end


# FOR CRON

	def self.retrieve_linkedin_companies

		date_diff = (Date.today  -  "2012-09-21".to_date).to_i

		ids_start = 1000000 + 500 * date_diff + 1
		ids_end = ids_start + 499

		#ids_start = 1040011 
		#ids_end = 1040500

		puts "ids_start: #{ids_start}\n"
		puts "ids_end: #{ids_end}\n"

		client = LinkedIn::Client.new(property(:linkedin_api_key), property(:linkedin_secret_key)) #1
		#client = LinkedIn::Client.new("uvdzbwf85huf", "Ac68GDkRakt7Ib0P") # raj #2
		#client = LinkedIn::Client.new("x8cgjnmp0n03", "frgGv43mZqFcvXpM") # jhlee #3
		#client.authorize_from_access(property(:linkedin_oauth_user_token), property(:linkedin_oauth_user_secret))

		companies = Array.new

		for i in ids_start..ids_end
			begin
				company =client.company(:id => i.to_s, :fields => %w(id name universal-name website-url industries logo-url employee-count-range locations:(address:(street1 city state postal-code country-code) contact-info:(phone1)))).to_hash

				unless company.blank?
					code, emplyee_count, employee_size, address, city, state, zipcode, phone, country = ""

					if company["industries"].present? and company["industries"]["total"].to_i > 0
						code = company["industries"]["all"][0].code
					end

					if (company["employee_count_range"].present?)
						employee_count = company["employee_count_range"]["code"]
						employee_size = company["employee_count_range"]["name"]
					end

					if (employee_count == "A" or employee_count == "B" or employee_count == "C" or employee_count == "D")
						if company["locations"]["total"].to_i>0
							address = company["locations"]["all"][0].address.street1
							city =company["locations"]["all"][0].address.city 
							state =company["locations"]["all"][0].address.state
							zipcode = company["locations"]["all"][0].address.postal_code
							phone = company["locations"]["all"][0].contact_info.phone1
							unless (company["locations"]["all"][0].address.country_code.blank?)
								country = from_country_code(company["locations"]["all"][0].address.country_code.upcase)
							end
						end

						field_company = {:name => company["name"], :address => address, :city => city, :state => state, :zipcode => zipcode, :phone => phone, :country => country, :industry =>code, :created_from => "linkedin" , :size => employee_size, :company_id => company["id"]}

						puts "Company ID linkedin_companies insertion #{field_company[:company_id].to_s}"

						cquery1 = "INSERT INTO linkedin_companies (created_at,linkedin,"
						cquery2 = ") VALUES ('#{Time.new.strftime("%Y-%m-%d %H:%M:%S")}','#{field_company[:company_id]}',"

						field_company.each do |key, value| 
							unless key.blank?
								unless key.to_s.eql?("company_id")
									cquery1+= "#{key},"
									cquery2+= "'" + value.to_s.gsub(/['"\\\x0]/,'\\\\\0') + "',"
								end
							end
						end
						cquery = cquery1.chop + cquery2.chop + ")"

						puts cquery+"\n"

						ActiveRecord::Base.connection.execute(cquery)

					else
						puts "company id #{i.to_s} employee_count_range is not in 1-200 \n"
					end # of of if size filter
				else
					puts "company id #{i.to_s} is not active \n"
				end # end of unless
			rescue
				puts "limit exceeded or fail to retrieve company id #{i.to_s} info\n"
			end # end of begin
		end # end of for
		puts "**********************Comapnies End*******************\n"
	end

#UPDATE linkedin_companies SET created_at=(REPLACE(created_at,'2012-09-28','2012-09-27')) WHERE created_at > '2012-09-27';

#select linkedin,created_at from linkedin_companies order by id desc limit 455,10;
#UPDATE linkedin_companies SET created_at=(REPLACE(created_at,'2012-12-15','2012-12-13')) WHERE created_at > '2012-12-15 00:00:00';
#select count(*) cnt, linkedin from linkedin_companies group by linkedin having cnt > 1;
#select * from linkedin_companies where linkedin  between 1041001 and 1041500 ;
#select linkedin,size, created_at from linkedin_companies where size='';

end
