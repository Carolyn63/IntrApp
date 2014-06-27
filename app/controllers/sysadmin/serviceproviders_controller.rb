class Sysadmin::ServiceprovidersController < Sysadmin::ResourcesController

	def new
		@for_update = false
		@form = params[:form].to_i
		@form ||= 1
		@which_form = "form" + @form.to_s
		if @form == 1
			if params[:name]!=nil
				session[:sp_details]=nil
				@name = CGI::unescape(params[:name])
				@name = CGI::unescape(params[:name])
				@addressLine1 = CGI::unescape(params[:addressLine1])
				@addressLine2 = CGI::unescape(params[:addressLine2])
				@city=CGI::unescape(params[:city])
				@state = CGI::unescape(params[:state])
				@country=CGI::unescape(params[:country])
				@zipCode = CGI::unescape(params[:zipCode])
			elsif session[:sp_details]!=nil
				@name= session[:sp_details][:name]
				@emailId=session[:sp_details][:email]
				@locale=session[:sp_details][:locale]
				@language=session[:sp_details][:language]
				@addressLine1 = session[:sp_details][:addressline1]
				@addressLine2 = session[:sp_details][:addressline2]
				@city = session[:sp_details][:city]
				@state = session[:sp_details][:state]
				@zipCode = session[:sp_details][:zipCode]
				@country = session[:sp_details][:country]
				@timezone=session[:sp_details][:timezone]
			end
		elsif @form == 2

		elsif @form == 3
			response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'features/', 'all')
			if response.code == '200'
				@features = ActiveSupport::JSON.decode(response.body)
				flash.now[:warning]  = t("controllers.get.empty.assigned_features") if @features.blank?
			else
				flash[:error]  = t("controllers.get.error.assigned_features")  + "<br />" + response.body
			end
		elsif @form == 4
			if $public_numbers.blank?
				response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'publicnumber/', 'available')
				if response.code == '200'
					$public_numbers = ActiveSupport::JSON.decode(response.body)              
					flash.now[:warning]  = t("controllers.get.empty.assigned_public_numbers") if $public_numbers.blank?
				else
					flash[:error]  = t("controllers.get.error.available_publicnumbers")  + "<br />" + response.body
				end
			end
			$public_numbers ||= Array.new
			@page_results = $public_numbers.paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
		end
	end


	def create
		$public_numbers = nil
		sp_name = params[:name].to_s
		action = params[:commit].downcase
		@form = params[:form].to_i
		case action
		when "cancel"
			session[:sys_add_sp_id] = nil
			session[:sp_details]=nil
			redirect_to  sysadmin_serviceproviders_path

		else
		########################@form 1
			if @form == 1
				session[:sp_details]={
				:name=>params[:serviceprovider][:name],
				:email=> params[:serviceprovider][:emailId],
				:locale=> params[:serviceprovider][:locale],
				:language=> params[:serviceprovider][:language],
				:addressline1=> params[:serviceprovider][:addressLine1],
				:addressline2=> params[:serviceprovider][:addressLine2],
				:city=> params[:serviceprovider][:city],
				:state=> params[:serviceprovider][:state],
				:country=> params[:serviceprovider][:country],
				:timezone=>params[:serviceprovider][:timezone],
				:zipcode => params[:serviceprovider][:zipCode],
				}
				content_json = {
					"name" => params[:serviceprovider][:name],
					"geographicDetails" => {
						"timezone" => params[:serviceprovider][:timezone], 
						"locale" => params[:serviceprovider][:locale],
						"language" => params[:serviceprovider][:language],
						"addressLine1" => params[:serviceprovider][:addressLine1],
						"addressLine2" => params[:serviceprovider][:addressLine2],
						"city" => params[:serviceprovider][:city],
						"state" => params[:serviceprovider][:state],
						"zipCode" => params[:serviceprovider][:zipCode],
						"country" => params[:serviceprovider][:country]
					},
					"emailId" => params[:serviceprovider][:emailId],
					"featureSet" => params[:serviceprovider][:featureSet], 
					"activeStatus" => params[:serviceprovider][:activeStatus] == "1" ? true : false
				}.to_json

				logger.info "Posting Json Data--: #{content_json}"

				response = IppbxApi.ippbx_post(session[:sys_admin], session[:sys_pass],'sys', 'serviceprovider', content_json)
				if response.code == '200'
					session[:sys_add_sp_id] = ActiveSupport::JSON.decode(response.body)["uid"]  #save the created serviceprovider id
					session[:sys_sp_name] = ActiveSupport::JSON.decode(response.body)["name"]
					flash[:notice]  = t("controllers.create.ok.sp_profile")
					session[:sp_details]=nil
				else
					@form -= 1
					flash[:error]  = t("controllers.create.error.sp_profile")  + "<br />" + response.body
				end

			##########################@form 2
			elsif @form == 2
				if session[:sys_add_sp_id].blank?
					@form = 0
				else
					content_json = {
						"emailId" => params[:serviceprovider][:emailId],
						"entityId" => session[:sys_add_sp_id],
						"geographicDetails" => {
							"timezone" => params[:serviceprovider][:timezone],
							"locale" => params[:serviceprovider][:locale],
							"language" => params[:serviceprovider][:language], 
							"addressLine1" => params[:serviceprovider][:addressLine2],
							"addressLine2" => params[:serviceprovider][:addressLine2],
							"city" => params[:serviceprovider][:city],
							"state" => params[:serviceprovider][:state],
							"zipCode" => params[:serviceprovider][:zipCode], 
							"country" => params[:serviceprovider][:country]
						},
						"type" => 2, 
						"password" => params[:serviceprovider][:password],
						"loginName" => params[:serviceprovider][:loginName]
					}.to_json

					logger.info "Posting Json Data 2: #{content_json}"

					response = IppbxApi.ippbx_post(session[:sys_admin], session[:sys_pass],'sys', 'serviceprovideradmin', content_json)

					if response.code == '200'
						IppbxNotifier.deliver_welcome_sp_admin(params[:serviceprovider][:loginName], params[:serviceprovider][:password], params[:serviceprovider][:emailId])
						flash[:notice]  = t("controllers.create.ok.sp_admin_profile")
					else
						@form -= 1
						flash[:error]  = t("controllers.create.error.sp_admin_profile")  + "<br />" + response.body
					end
				end

			#############################@form 3
			elsif @form == 3
				if session[:sys_add_sp_id].blank?
					@form = 0
				else
					features = Array.new(params[:row][:count].to_i)
					for i in 0..(params[:row][:count].to_i - 1)
						features[i] = "{\"featureCode\":\""+params[:featureCode][i.to_s]+"\",\"assigned\":"+ params[:assign][i.to_s].to_s + "}"
						logger.info "-=-=-==--=-^_^#{features[i].to_s}"
					end
					features_str = features.to_sentence(:skip_last_comma => true, :connector => ", ")
					content_json ="{\"serviceProvider\":{\"uid\":" + session[:sys_add_sp_id] + "},\"features\":[" + features_str + "]}"
					logger.info "Posting Json Data 3: #{content_json}"
					response = IppbxApi.ippbx_put(session[:sys_admin], session[:sys_pass],'sys', 'serviceproviderfeatures', content_json)

					if response.code == '200'
						flash[:notice]  = t("controllers.assign.ok.features")
					else
						@form -= 1
						flash[:error]  = t("controllers.assign.error.features")  + "<br />" + response.body
					end
				end

			#######################@form 4
			elsif @form == 4
				if session[:sys_add_sp_id].blank?
					@form = 0
				else
					if params[:serviceprovider][:range_from]!="" and params[:serviceprovider][:range_to]!=""
						response = IppbxApi.ippbx_put(session[:sys_admin], session[:sys_pass],'sys', 'publicnumber/assign/'+ params[:serviceprovider][:range_from] + 'to' + params[:serviceprovider][:range_to] + '/serviceprovider/' + session[:sys_add_sp_id].to_s, nil)
						if response.code == '200'
							flash[:notice]  = t("controllers.assign.ok.public_numbers")
						else
							flash[:notice]  = t("controllers.assign.error.public_numbers")
						end
					else
						for i in 0..(params[:row][:count].to_i - 1)
							if params[:assign][i.to_s] == true.to_s
								response = IppbxApi.ippbx_put(session[:sys_admin], session[:sys_pass],'sys', 'publicnumber/assign/'+ params[:number][i.to_s] + '/serviceprovider/' + session[:sys_add_sp_id].to_s, nil)
								response_code = response.code
								if response.code != '200'
									do_fail =true
									@form -= 1
									flash[:error]  = t("controllers.assign.error.public_numbers")  + "<br />" + response.body
								end
							end
						end #for

						flash[:notice]  = t("controllers.assign.ok.public_numbers") unless do_fail
					end #else no range
				end #else
			end #form4

			if action == "next"
				@form += 1
				redirect_to  new_sysadmin_serviceprovider_path(:form => @form)
			elsif action == "finish"
				session[:sys_add_sp_id] = nil
				redirect_to  sysadmin_serviceproviders_path
			end
		end
	end


	def update
		$public_numbers = nil
		action = params[:commit].downcase
		@form = params[:form].to_i
		@which_form = "form" + @form.to_s
		case action
			when "cancel"
				redirect_to  sysadmin_serviceproviders_path
			else

				#############################@form 1
				if @form == 1
					content_json = {
						"uid" => params[:id].to_i, 
						"geographicDetails" => {
							"uid" => params[:geographicDetails][:uid].to_i,
							"timezone" => params[:serviceprovider][:timezone], 
							"locale" => params[:serviceprovider][:locale],
							"language" => params[:serviceprovider][:language],
							"addressLine1" => params[:serviceprovider][:addressLine1],
							"addressLine2" => params[:serviceprovider][:addressLine2],
							"city" => params[:serviceprovider][:city],
							"state" => params[:serviceprovider][:state],
							"zipCode" => params[:serviceprovider][:zipCode],
							"country" => params[:serviceprovider][:country]
						},
						"name" => params[:serviceprovider][:name],
						"emailId" => params[:serviceprovider][:emailId],
						"activeStatus" => params[:serviceprovider][:activeStatus] == "1" ? true : false
					}.to_json

					logger.info "Puting Json Data: #{content_json}"
					response = IppbxApi.ippbx_put(session[:sys_admin], session[:sys_pass],'sys', 'serviceprovider', content_json)
					if response.code == '200'
						flash[:notice]  = t("controllers.update.ok.sp_profile")
					else
						@form -= 1
						flash[:error]  = t("controllers.update.error.sp_profile")  + "<br />" + response.body
					end

				#############################@form 2
				elsif @form == 2
					# content_json = {"uid" => params[:serviceproviderAdmin][:uid].to_i, "emailId" => params[:serviceprovider][:emailId],
					# "geographicDetails" => {"uid" => params[:geographicDetails][:uid].to_i, "timezone" => params[:serviceprovider][:timezone],
					# "zipCode" => params[:serviceprovider][:zipCode], "locale" => params[:serviceprovider][:locale],"state" => params[:serviceprovider][:state],
					# "language" => params[:serviceprovider][:language], "addressLine2" => params[:serviceprovider][:addressLine2],
					# "addressLine1" => params[:serviceprovider][:addressLine2],"city" => params[:serviceprovider][:city],"country" => params[:serviceprovider][:country]},
					# "password" => params[:serviceprovider][:password]}.to_json

					## Can not update password, will cause a mismatch, requires to be checked

					content_json = {
						"uid" => params[:serviceproviderAdmin][:uid].to_i, 
						"emailId" => params[:serviceprovider][:emailId],
						"geographicDetails" => {
							"uid" => params[:geographicDetails][:uid].to_i, 
							"timezone" => params[:serviceprovider][:timezone],
							"locale" => params[:serviceprovider][:locale],
							"language" => params[:serviceprovider][:language], 
							"addressLine1" => params[:serviceprovider][:addressLine2],
							"addressLine2" => params[:serviceprovider][:addressLine2],
							"city" => params[:serviceprovider][:city],
							"state" => params[:serviceprovider][:state],
							"zipCode" => params[:serviceprovider][:zipCode], 
							"country" => params[:serviceprovider][:country]
						}
					}.to_json

					logger.info "Putting Json Data 2: #{content_json}"
					response = IppbxApi.ippbx_put(session[:sys_admin], session[:sys_pass],'sys', 'serviceprovideradmin', content_json)
					if response.code == '200'
						flash[:notice]  = t("controllers.update.ok.sp_admin_profile")
					else
						@form -= 1
						flash[:error]  = t("controllers.update.error.sp_admin_profile")  + "<br />" + response.body
					end

				#############################@form 3
				elsif @form == 3
					features = Array.new(params[:row][:count].to_i)
					for i in 0..(params[:row][:count].to_i - 1)
						features[i] = "{\"featureCode\":\""+params[:featureCode][i.to_s]+"\",\"assigned\":"+ params[:assign][i.to_s].to_s + "}"
					end
					features_str = features.to_sentence(:skip_last_comma => true, :connector => ", ")
					content_json ="{\"serviceProvider\":{\"uid\":" + params[:id] + "},\"features\":[" + features_str + "]}"
					logger.info "Posting Json Data 3: #{content_json}"
					response = IppbxApi.ippbx_put(session[:sys_admin], session[:sys_pass],'sys', 'serviceproviderfeatures', content_json)

					if response.code == '200'
						flash[:notice]  = t("controllers.assign.ok.features")
					else
						@form -= 1
						flash[:error]  = t("controllers.assign.error.features")  + "<br />" + response.body
					end

				#######################@form 4
				elsif @form == 4
					if params[:serviceprovider][:range_from]!="" and params[:serviceprovider][:range_to]!=""
						response = IppbxApi.ippbx_put(session[:sys_admin], session[:sys_pass],'sys', 'publicnumber/assign/'+ params[:serviceprovider][:range_from] + 'to' + params[:serviceprovider][:range_to] + '/serviceprovider/' + params[:id].to_s, nil)
						if response.code == '200'
							flash[:notice]  = t("controllers.assign.ok.public_numbers")
						else
							flash[:notice]  = t("controllers.assign.error.public_numbers")
						end
					else
						for i in 0..(params[:row][:count].to_i - 1)
							if params[:assign][i.to_s] == true.to_s
								response = IppbxApi.ippbx_put(session[:sys_admin], session[:sys_pass],'sys', 'publicnumber/assign/'+ params[:number][i.to_s] + '/serviceprovider/' + params[:id].to_s, nil)
								response_code = response.code
								if response.code != '200'
									do_fail =true
									@form -= 1
									flash[:error]  = t("controllers.assign.error.public_numbers")  + "<br />" + response.body
								end
							end
						end #for
					end

					flash[:notice]  = t("controllers.assign.ok.public_numbers") unless do_fail
				end

				if action == "next"
					@form += 1
					redirect_to  edit_sysadmin_serviceprovider_path(params["id"], :form => @form)
				elsif action == "finish"
					@form = nil
					redirect_to  sysadmin_serviceproviders_path
				end
			end
	end

	def edit
		@for_update = true
		@form = params[:form].to_i
		@form ||= 1
		@which_form = "form" + @form.to_s

		if @form == 1
			#retrieve serviceprovider
			response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'serviceprovider/', params[:id])
			if response.code == '200'
				@response_decode = ActiveSupport::JSON.decode(response.body)
				@name = @response_decode["name"]
				@emailId = @response_decode["emailId"]
				@addressLine1 = @response_decode["geographicDetails"]["addressLine1"]
				@addressLine2 = @response_decode["geographicDetails"]["addressLine2"]
				@city = @response_decode["geographicDetails"]["city"]
				@state = @response_decode["geographicDetails"]["state"]
				@zipCode = @response_decode["geographicDetails"]["zipCode"]
				@locale = @response_decode["geographicDetails"]["locale"]
				@country = @response_decode["geographicDetails"]["country"]
				@language = @response_decode["geographicDetails"]["language"]
				@timezone = @response_decode["geographicDetails"]["timezone"]
				@geographic_details_uid = @response_decode["geographicDetails"]["uid"]
				@uid = params[:id]
			else
				flash[:error]  = t("controllers.get.error.sp_profile")  + "<br />" + response.body
			end

		elsif @form == 2
			response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'serviceprovideradmin/', params[:id])
			if response.code == '200'
				@response_decode = ActiveSupport::JSON.decode(response.body)
				@loginName = @response_decode["loginName"]
				@emailId = @response_decode["emailId"]
				#@password = @response_decode["password"]
				@password = ""
				@addressLine1 = @response_decode["geographicDetails"]["addressLine1"]
				@addressLine2 = @response_decode["geographicDetails"]["addressLine2"]
				@locale = @response_decode["geographicDetails"]["locale"]
				@city = @response_decode["geographicDetails"]["city"]
				@state = @response_decode["geographicDetails"]["state"]
				@zipCode = @response_decode["geographicDetails"]["zipCode"]
				@country = @response_decode["geographicDetails"]["country"]
				@language = @response_decode["geographicDetails"]["language"]
				@timezone = @response_decode["geographicDetails"]["timezone"]
				@geographic_details_uid = @response_decode["geographicDetails"]["uid"]
				@serviceprovider_admin_uid = @response_decode["uid"]
				@uid = params[:id]
			elsif response.code == '400' and response.body.include? 'No admin record found'
				session[:sys_add_sp_id] = params[:id]
				flash[:warning]  = t("controllers.misc.warning.edit_non_created_sp_admin")
				redirect_to new_sysadmin_serviceprovider_path(:form => @form)
			else
				flash[:error]  = t("controllers.get.error.sp_admin_profile")  + "<br />" + response.body
			end

		elsif @form == 3
			response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'features/', 'all')
			if response.code == '200'
				@features = ActiveSupport::JSON.decode(response.body)
				flash.now[:warning]  = t("controllers.get.empty.assigned_features") if @features.blank?
			else
				flash[:error]  = t("controllers.get.error.assigned_features")  + "<br />" + response.body
			end

		elsif @form == 4
			$public_numbers = nil
			response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'publicnumber/', 'available')
			if response.code == '200'
				$public_numbers = ActiveSupport::JSON.decode(response.body)              
				flash.now[:warning]  = t("controllers.get.empty.assigned_public_numbers") if $public_numbers.blank?
			else
				flash[:error]  = t("controllers.get.error.assigned_public_numbers")  + "<br />" + response.body
			end
			$public_numbers ||= Array.new
			@page_results = $public_numbers.paginate(:page => params[:page], :per_page => property(:results_per_page).to_i)
		end
	end

	def index
		if params[:commit] == 'Search'
			criteria = 'criteria={'
			criteria += 'name:'+CGI::escape(params[:name]) + ';' unless params[:name].blank?
			criteria += 'emailId:'+CGI::escape(params[:emailId]) + ';' unless params[:emailId].blank?
			criteria += 'activeStatus:'+CGI::escape(params[:activeStatus]) + ';' unless params[:activeStatus].blank?
			criteria += 'city:'+CGI::escape(params[:city]) + ';' unless params[:city].blank?
			criteria += '}'
			response = ippbx_search('sys', 'resource=ServiceProvider&orderBy=name&sortOrder=asc&'+criteria, nil)
			if response.code == '200'
				@serviceproviders = ActiveSupport::JSON.decode(response.body)
				flash.now[:warning]  = t("controllers.search.empty") if @serviceproviders.blank?
			else
				flash[:error]  = t("controllers.search.error.serviceproviders_list")  + "<br />" + response.body
			end
		else
			response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'serviceprovider/', 'all')
			if response.code == '200'
				@serviceproviders = ActiveSupport::JSON.decode(response.body)
			else
				flash[:error]  = t("controllers.get.error.serviceproviders_list")  + "<br />" + response.body
			end
		flash.now[:warning]  = t("controllers.get.empty.serviceproviders_list") unless !@serviceproviders.blank?
		end
		@serviceproviders ||= ''
	end

	def destroy
		response = IppbxApi.ippbx_get(session[:sys_admin], session[:sys_pass],'sys', 'serviceprovideradmin/', params[:id])
		if response.code == '200'
			@response_decode = ActiveSupport::JSON.decode(response.body)
			loginName = @response_decode["loginName"]
			emailId = @response_decode["emailId"]
		end
		if !params[:id].blank?
			response = IppbxApi.ippbx_delete(session[:sys_admin], session[:sys_pass],'sys', 'serviceprovider/', params[:id])
			if response.code == '200'
				flash[:notice]  = t("controllers.delete.ok.serviceprovider")
				IppbxNotifier.deliver_sp_admin_delete(loginName, emailId) unless emailId.blank?
			else
			flash[:error]  = t("controllers.delete.error.serviceprovider")  + "<br />" + response.body
			end
		end
		redirect_to  sysadmin_serviceproviders_path
	end

end
