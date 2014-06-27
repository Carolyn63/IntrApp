class CloudStorageController < ApplicationController
  def index

    @api_result = ""
    @to_do = params[:to_do]

    if @to_do == "Create_Business"

=begin

      #--------------------------API 1: Create a business(Collection and Admin)--------------------------#
      #step 1. Login as Service Provider Admin
      topLevelCollection = "Vendor1"
      topAdmin = "admin1"
      topAPass = "password"
      service = Services::DigidataApi::Api.new(topAdmin, topAPass, topLevelCollection)

      #step 2. Create bussiness collection and admin
      bizLevelCollection = "otogomobile"
      bizAdmin = "otogoadmin"
      bizPass = "mobile1"
      biz_quota = 214748364800
      biz_admin_email = "otogoadmin@otogomobile.net"
      response = service.create_biz_and_admin(bizLevelCollection, biz_quota, bizAdmin, bizPass, biz_admin_email)

      #code just for output
      if /^20/.match(response.code)
        @api_result = "Create a business(Collection and Admin) OK! <br/> Http code: "+response.code+ "<br/> Result: "+response.message
      else
        @api_result = "Create a business(Collection and Admin) Failed! <br/> Http code: "+response.code+ "<br/> Result: "+response.message + "<br/> <br/>  Response body:" +response.body
      end
=end

      #--------------------------API 1: Create a business(Collection and Admin)--------------------------#
      #step 1. Login as Service Provider Admin
      spLevelCollection = "otogomobile"
      spAdmin = "otogoadmin"
      spAPass = "mobile1"
      service = Services::DigidataApi::Api.new(spAdmin, spAPass, spLevelCollection)


      #step 2. Create bussiness collection and admin
      bizLevelCollection = "Test3"
      bizAdmin = "testadmin3"
      bizPass = "123456"
      biz_quota = 10730
      biz_admin_email = "testadmin3@otogomobile.net"
      response = service.create_biz_and_admin(bizLevelCollection, biz_quota, bizAdmin, bizPass, biz_admin_email)

      #code just for output
      if /^20/.match(response.code)
        @api_result = "Create a business(Collection and Admin) OK! <br/> Http code: "+response.code+ "<br/> Result: "+response.message
      else
        @api_result = "Create a business(Collection and Admin) Failed! <br/> Http code: "+response.code+ "<br/> Result: "+response.message + "<br/> <br/>  Response body:" +response.body
      end
    # @api_result = ""
    # @to_do = params[:to_do]
    # if @to_do == "Create_Business"
    # company_id = 159
    # company = Company.find_by_id(company_id)
    # ent_username = company.name.gsub(/[\W]/i, "")
    # ent_username = ent_username.slice(0,6)+company.id.to_s
    # ent_username = ent_username.downcase
    # ent_password = generate_password(8)
    # encrypt_password = Tools::AESCrypt.new.encrypt(ent_password)
    # uid = company_id
    #
    # cloud_sp = Cloudstorage.find_by_admin_type_and_name("serviceprovider", 'otogomobile')
    # sp_username = cloud_sp.login
    # sp_password  = Tools::AESCrypt.new.decrypt(cloud_sp.password)
    # sp_level_collection = cloud_sp.name
    # service = Services::DigidataApi::Api.new(sp_username, sp_password, sp_level_collection)
    # @api_result = "params for service #{sp_username}, #{sp_password}, #{sp_level_collection}"
    #
    # biz_level_collection = company.name
    # biz_quota =  10 * 1024 * 1024 * 1024
    # biz_admin = ent_username
    # biz_pass = ent_password
    # biz_admin_email = ent_username + '' + property(:sogo_email_domain)
    # digidata_response = service.create_biz_and_admin(biz_level_collection, biz_quota, biz_admin, biz_pass, biz_admin_email)
    # @api_result = "params for company #{biz_level_collection}, #{biz_quota}, #{biz_admin}, #{biz_pass}, #{biz_admin_email}"
    #
    # @api_result = "response: #{digidata_response.code},#{digidata_response.body}"
    #
    # response = digidata_response.code
    # if /^20/.match(response)
    # @api_result = "cloud storage creation successful for company #{company_id}, #{digidata_response.message}"
    # else
    # @api_result = "cloud storage creation failed for company #{company_id}, #{digidata_response.message}"
    # end

    #--------------------------------------------------------------------------------------------------#
    elsif @to_do == "Assign_Owner"
      #step 1. Login as Service Provider Admin
      spLevelCollection = "otogomobile"
      spAdmin = "otogoadmin"
      spAPass = "mobile1"
      service = Services::DigidataApi::Api.new(spAdmin, spAPass, spLevelCollection)

      #step 2. assign owner
      bizLevelCollection = "Alainis Engineering"
      response = service.assign_owner(bizLevelCollection)

      #code just for output
      if /^20/.match(response.code)
        @api_result = "Assign owner OK! <br/> Http code: "+response.code+ "<br/> Result: "+response.message
      else
        @api_result = "Assign owner Failed! <br/> Http code: "+response.code+ "<br/> Result: "+response.message + "<br/> <br/>  Response body:" +response.body
      end
    #-------------------------------------------------------------------------------------------------------#
    elsif @to_do == "Delete_Business"
      #--------------------------API 2: Delete a business from sp collection--------------------------#
      #step 1. Login as Service Provider Admin
      spLevelCollection = "otogomobile"
      spAdmin = "otogoadmin"
      spAPass = "mobile1"
      service = Services::DigidataApi::Api.new(spAdmin, spAPass, spLevelCollection)

      #step 2. create user
      bizLevelCollection = "Norwich Golf Equipments Ltd."
      response = service.delete_biz(bizLevelCollection)

      #code just for output
      if /^20/.match(response.code)
        @api_result = "Delete a business from a sp collection OK! <br/> Http code: "+response.code+ "<br/> Result: "+response.message
      else
        @api_result = "Delete a business from a sp collection Failed! <br/> Http code: "+response.code+ "<br/> Result: "+response.message + "<br/> <br/>  Response body:" +response.body
      end
    #-------------------------------------------------------------------------------------------------------#
    elsif @to_do == "Create_User"
      #--------------------------API 3: Create a user for a bussiness collection--------------------------#
      #step 1. login as bussiness collection admin
      bizLevelCollection = "Test10"
      bizAdmin = "test10admin"
      bizPass = "123456"
      service = Services::DigidataApi::Api.new(bizAdmin, bizPass, bizLevelCollection)

      #step 2. create user
      user_login = "testuser10"
      user_pass = "123456"
      user_quota = "1073"
      user_email = "testuser10@gmail.com"
      response = service.create_user(bizLevelCollection, user_login, user_pass, user_quota, user_email)

      #code just for output
      if /^20/.match(response.code)
        @api_result = "Create a user for a bussiness collection OK! <br/> Http code: "+response.code+ "<br/> Result: "+response.message
      else
        @api_result = "Create a user for a bussiness collection Failed! <br/> Http code: "+response.code+ "<br/> Result: "+response.message + "<br/> <br/>  Response body:" +response.body
      end
    #-------------------------------------------------------------------------------------------------------#
    elsif @to_do == "Delete_User"
      #--------------------------API 4: Delete a user for a bussiness collection--------------------------#
      #step 1. login as bussiness collection admin
      bizLevelCollection = "Norwich Golf Equipments Ltd."
      bizAdmin = "norwichg174"
      bizPass = "ZGbkZR8n"
      service = Services::DigidataApi::Api.new(bizAdmin, bizPass, bizLevelCollection)

      #step 2. create user
      user_login = "norwichg174"
      response = service.delete_user(bizLevelCollection, user_login)

      #code just for output
      if /^20/.match(response.code)
        @api_result = "Delete a user from a bussiness collection OK! <br/> Http code: "+response.code+ "<br/> Result: "+response.message
      else
        @api_result = "Delete a user from a bussiness collection Failed! <br/> Http code: "+response.code+ "<br/> Result: "+response.message + "<br/> <br/>  Response body:" +response.body
      end
    #-------------------------------------------------------------------------------------------------------#
    elsif @to_do == "Update_User"
      #--------------------------API 5: Update a user for a bussiness collection--------------------------#
      #step 1. login as bussiness collection admin
      bizLevelCollection = "Norwich Golf Equipments Ltd."
      bizAdmin = "norwichg174"
      bizPass = "ZGbkZR8n"
      service = Services::DigidataApi::Api.new(bizAdmin, bizPass, bizLevelCollection)

      #step 2. create user
      user_login = "testuser10"
      firstName = "Qingyaabc"
      lastName = "chenabc"
      emailAddress = "abcemail@fff.com"
      response = service.update_user(bizLevelCollection, user_login, firstName, lastName, emailAddress)

      #code just for output
      if /^20/.match(response.code)
        @api_result = "Update a user for a bussiness collection OK! <br/> Http code: "+response.code+ "<br/> Result: "+response.message
      else
        @api_result = "Update a user for a bussiness collection Failed! <br/> Http code: "+response.code+ "<br/> Result: "+response.message + "<br/> <br/>  Response body:" +response.body
      end
    #-------------------------------------------------------------------------------------------------------#
    end
    logger.info "====================#{@api_result}"
  end

end

