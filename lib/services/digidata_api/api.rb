require 'rubygems'
require 'json'
require 'net/http'

module Services
  module DigidataApi
    class Api < ActiveRecord::Base
      def initialize(user, pass, collection)
        # credentials for the primary admin account

        # user collection for which the above account is an admin
        # - this is the UC in which we build a new user collection
        # representing a small business
        #@top_level_collection = collection
        # this is the name of the small business we create - for
        # simplicity I'm just using a random string (eg. 'qsyndpto.biz')
        #@new_small_business_name = bizName

        #@base_uri = "http://core5qa.digidatagrid.com/current/rest"
        @base_uri = "http://core5demo.digidatagrid.com/otogo/rest"
        @username = user
        @password = pass
        @admin_level_collection = collection
        @content_type = "application/vnd.com.digidata.ddvs+json;v=1;c=1"
      end

      # get a new DDRS document from a DDRS link and return the
      # response (if any) in the form of a Ruby hash
      def get(link = { 'rel' => nil, 'href' => 'index' })

        uri = URI("#{@base_uri}/#{link['href']}")

        req = Net::HTTP::Get.new(uri.request_uri)
        req.basic_auth @username, @password
        req['Accept'] = @content_type

        rsp = Net::HTTP.start(uri.host, uri.port) {|h|
          h.request(req)
        }

        # this is just a little debugging output
        #rel_text = link['rel'] == nil ? '/' : "rel='#{link['rel']}'"
        #logger.info  "=====================GET #{rel_text} => #{rsp.code} (#{rsp.message})"

        return rsp
      #return JSON.parse(rsp.body)

      end

      # delete an entity by its DDRS link
      def delete(link)
        uri = URI("#{@base_uri}/#{link['href']}")
        req = Net::HTTP::Delete.new(uri.request_uri)
        req.basic_auth @username, @password
        req['Accept'] = @content_type

        rsp = Net::HTTP.start(uri.host, uri.port) {|h|
          h.request(req)
        }

        return rsp
      end

      # put a Ruby hash to a DDRS link and return the response (if any)
      # in the form of another Ruby hash
      def put(link, hash)
        uri = URI("#{@base_uri}/#{link['href']}")
        req = Net::HTTP::Put.new(uri.request_uri)
        req.basic_auth @username, @password
        req['Accept'] = @content_type
        req['Content-Type'] = @content_type

        req.body = JSON.generate(hash)

        rsp = Net::HTTP.start(uri.host, uri.port) {|h|
          h.request(req)
        }

        return rsp
      end

      # post a Ruby hash to a DDRS link and return the response (if any)
      # in the form of another Ruby hash
      def post(link, hash)
        uri = URI("#{@base_uri}/#{link['href']}")
        req = Net::HTTP::Post.new(uri.request_uri)
        req.basic_auth @username, @password
        req['Accept'] = @content_type
        req['Content-Type'] = @content_type

        req.body = JSON.generate(hash)

        rsp = Net::HTTP.start(uri.host, uri.port) {|h|
          h.request(req)
        }

        # this is just a little debugging output
        #logger.info  "=====================POST rel='#{link['rel']}' => #{rsp.code} (#{rsp.message})"

        return rsp
      #return rsp.body == nil ? { } : JSON.parse(rsp.body)
      end

      def find_member_by_property(source, property_name, value)
        return source['members'].select { |k| k['properties'][property_name] == value }[0]
      end

      # this is a handy extension method that finds a DDRS link
      # by querying a document's Associations Aspect for links
      # with a rel attribute equal to the 'rel' parameter
      def find_link_by_relation(source, rel)
        links = source['associations']['links'] # links to other resources
        return links.select { |k| k['rel'] == rel }[0]
      end

      def delete_biz(bizName)        
        if bizName.blank?
          logger.info "Execution error! The reason is at least one of the following params is not supplied to execute the API: bizName. Please Check!"
        return
        end

        logger.info "Calling function delete_biz(bizName), Parameters are (by function order): businessName(#{bizName})"
        
        ###
        ### goal 3: as the new administrator, create a new user
        ###

        ## step 1: login as the new administrator

        rsp = self.get()
        unless /^20/.match(rsp.code)
          logger.error  "delete_biz(),  when trying to load login page. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info  "delete_biz(),  load login page, OK!"
        homepage = rsp.body == nil ? { } : JSON.parse(rsp.body)
        login_link = find_link_by_relation(homepage, 'login')

        rsp = self.get(login_link)
        unless /^20/.match(rsp.code)
          logger.error  "delete_biz(),  when trying to login as sp admin. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info "delete_biz(), Login as sp admin, OK!"
        me = rsp.body == nil ? { } : JSON.parse(rsp.body)

        #
        # ## step 2: find the entity representing the small business UC
        #
        all_ucs_link = find_link_by_relation(me, 'memberships')
        rsp = self.get(all_ucs_link)
        unless /^20/.match(rsp.code)
          logger.error  "delete_biz(),  when trying to get memberships. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info "delete_biz(), Get all the memberships,  OK!"
        all_ucs = rsp.body == nil ? { } : JSON.parse(rsp.body)

        target_biz = find_member_by_property(all_ucs, 'name', bizName)

        self_link = find_link_by_relation(target_biz, 'self')
        
        logger.info "=====================delete biz self_link    #{self_link}"

        rsp = self.delete(self_link)
        unless /^20/.match(rsp.code)
          logger.error  "delete_biz(),  when trying to delete business by delete. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info "delete_biz(), delete business '#{bizName}', OK!"

        # #send email to user
        # admin_url = "http://core5qa.digidatagrid.com/current/admin/Core/Login.aspx"
        # user_url = "http://core5qa.digidatagrid.com/current/obw/Core/Login.aspx"
        # Notifier.deliver_cloud_storage_created(@user_login, @user_password, @user_email, admin_url, user_url)
        # logger.info "Send an email to '#{@user_email}' for user '#{@user_login}' of Small Bussiness '#{bizName}' OK!"

        #return the final response
        return  rsp
      end

       def update_user(bizName, user_login, firstName, lastName, emailAddress)
    
        if bizName.blank? or user_login.blank?
          logger.info "Execution error! The reason is at least one of the following params is not supplied to execute the API: bizName, user_login. Please Check!"
        return
        end
        
        logger.info "Calling function update_user(bizName, login, firstName, lastName, emailAddress), Parameters are (by function order): businessName(#{bizName}), user_login(#{user_login}), firstName(#{firstName}), lastName(#{lastName}), emailAddress(#{emailAddress})"

        ###
        ### goal 3: as the new administrator, create a new user
        ###

        ## step 1: login as the new administrator

        rsp = self.get()
        unless /^20/.match(rsp.code)
          logger.error  "update_user(),  when trying to load login page. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info  "update_user(),  load login page, OK!"
        homepage = rsp.body == nil ? { } : JSON.parse(rsp.body)
        login_link = find_link_by_relation(homepage, 'login')

        rsp = self.get(login_link)
        unless /^20/.match(rsp.code)
          logger.error  "update_user(),  when trying to login as user. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info "update_user(), Login as user, OK!"
        me = rsp.body == nil ? { } : JSON.parse(rsp.body)

        #
        # ## step 2: find the entity representing the small business UC
        #
        all_ucs_link = find_link_by_relation(me, 'memberships')
        rsp = self.get(all_ucs_link)
        unless /^20/.match(rsp.code)
          logger.error  "update_user(),  when trying to get memberships. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info "update_user(), Get all the memberships,  OK!"
        all_ucs = rsp.body == nil ? { } : JSON.parse(rsp.body)

        sb_uc = find_member_by_property(all_ucs, 'name', bizName)
        ## step 3: create the new user by POSTing a representation
        ##         to the 'members' relation of our new UC

        # POST it to the small business members collection
        members_link = find_link_by_relation(sb_uc, 'members')
        rsp = self.get(members_link)
        unless /^20/.match(rsp.code)
          logger.error  "update_user(),  when trying to get all the users of business collection #{bizName}. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info "update_user(), get all the users of business collection #{bizName},  OK!"
        all_biz_users = rsp.body == nil ? { } : JSON.parse(rsp.body)


        target_user = find_member_by_property(all_biz_users, 'login', user_login)
        

        target_user['properties']['firstName'] = firstName unless   firstName.blank?
        target_user['properties']['lastName'] = lastName   unless   lastName.blank?
        target_user['properties']['emailAddress'] = emailAddress     unless   emailAddress.blank?
        self_link = find_link_by_relation(target_user, 'self')

        rsp = self.put(self_link, target_user)
        unless /^20/.match(rsp.code)
          logger.error  "update_user(),  when trying to update user by put. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info "update_user(), delete user '#{user_login}', OK!"

        # #send email to user
        # admin_url = "http://core5qa.digidatagrid.com/current/admin/Core/Login.aspx"
        # user_url = "http://core5qa.digidatagrid.com/current/obw/Core/Login.aspx"
        # Notifier.deliver_cloud_storage_created(user_login, @user_password, @user_email, admin_url, user_url)
        # logger.info "Send an email to '#{@user_email}' for user '#{user_login}' of Small Bussiness '#{bizName}' OK!"

        #return the final response
        return  rsp
      end

      def delete_user(bizName, user_login)

        if bizName.blank? or user_login.blank?
          logger.info "Execution error! The reason is at least one of the following params is not supplied to execute the API: bizName, user_login. Please Check!"
        return
        end
        
        logger.info "Calling function delete_user(bizName, user_login), Parameters are (by function order): businessName(#{bizName}), user_login(#{user_login})"
        ###
        ### goal 3: as the new administrator, create a new user
        ###

        ## step 1: login as the new administrator

        rsp = self.get()
        unless /^20/.match(rsp.code)
          logger.error  "delete_user(),  when trying to load login page. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info  "delete_user(),  load login page, OK!"
        homepage = rsp.body == nil ? { } : JSON.parse(rsp.body)
        login_link = find_link_by_relation(homepage, 'login')

        rsp = self.get(login_link)
        unless /^20/.match(rsp.code)
          logger.error  "delete_user(),  when trying to login as user. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info "delete_user(), Login as user, OK!"
        me = rsp.body == nil ? { } : JSON.parse(rsp.body)

        #
        # ## step 2: find the entity representing the small business UC
        #
        all_ucs_link = find_link_by_relation(me, 'memberships')
        rsp = self.get(all_ucs_link)
        unless /^20/.match(rsp.code)
          logger.error  "delete_user(),  when trying to get memberships. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info "delete_user(), Get all the memberships,  OK!"
        all_ucs = rsp.body == nil ? { } : JSON.parse(rsp.body)

        sb_uc = find_member_by_property(all_ucs, 'name', bizName)
        ## step 3: create the new user by POSTing a representation
        ##         to the 'members' relation of our new UC

        # POST it to the small business members collection
        members_link = find_link_by_relation(sb_uc, 'members')
        rsp = self.get(members_link)
        unless /^20/.match(rsp.code)
          logger.error  "delete_user(),  when trying to get all the users of business collection #{bizName}. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info "delete_user(), get all the users of business collection #{bizName},  OK!"
        all_biz_users = rsp.body == nil ? { } : JSON.parse(rsp.body)

        target_user = find_member_by_property(all_biz_users, 'login', user_login)

        self_link = find_link_by_relation(target_user, 'self')
        
        #logger.info "=====================delete user self_link    #{self_link}"

        rsp = self.delete(self_link)
        unless /^20/.match(rsp.code)
          logger.error  "delete_user(),  when trying to delete user by delete. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info "delete_user(), delete user '#{user_login}', OK!"

        # #send email to user
        # admin_url = "http://core5qa.digidatagrid.com/current/admin/Core/Login.aspx"
        # user_url = "http://core5qa.digidatagrid.com/current/obw/Core/Login.aspx"
        # Notifier.deliver_cloud_storage_created(user_login, @user_password, @user_email, admin_url, user_url)
        # logger.info "Send an email to '#{@user_email}' for user '#{user_login}' of Small Bussiness '#{bizName}' OK!"

        #return the final response
        return  rsp
      end

	def create_biz_and_admin(bizName, quota, login, pass, admin_email)
		if bizName.blank? or quota.blank? or login.blank? or pass.blank? or admin_email.blank?
			logger.error "Execution error! The reason is at least one of the following params is not supplied to execute the API: bizName, quota, login, pass, admin_email. Please Check!"
			return
		end
		logger.info "Calling function create_biz_and_admin(bizName, quota, login, pass, admin_email), Parameters are (by function order): businessName(#{bizName}), quota(#{quota}), login(#{login}), pass(#{pass}), admin_email(#{admin_email})"
		# retrieve our service's "home page"
		rsp = self.get()

		unless /^20/.match(rsp.code)
			logger.error  "create_biz_and_admin(), when trying to load login page. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
			return rsp
		end
		logger.info "create_biz_and_admin(), Load login page, OK!"
		homepage = rsp.body == nil ? { } : JSON.parse(rsp.body)

		# retrieve our administrator's user entity via the 'login' relation
		login_link = find_link_by_relation(homepage, 'login')

		logger.info "login_link: #{login_link.to_json}"
		logger.info "username: #{@username}"
		logger.info "password: #{@password}"
		logger.info "admin_level_collection: #{@admin_level_collection}"

		rsp = self.get(login_link)
		unless /^20/.match(rsp.code)
			logger.error  "create_biz_and_admin(), when trying to login as bussiness top level admin. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
			return rsp
		end
		logger.info "create_biz_and_admin(), Login as Top level Collection Admin, OK!"
		me = rsp.body == nil ? { } : JSON.parse(rsp.body)

		###
		### goal 1: create a new user collection for our small business
		###

		## step 1: find our top-level user collection, of which our
		##         small business user collections should be children

		# find the set of all UCs of which our admin is a member
		all_ucs_link = find_link_by_relation(me, 'memberships')
		rsp = self.get(all_ucs_link)
		unless /^20/.match(rsp.code)
			logger.error  "create_biz_and_admin(),  when trying to get memberships. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
			return rsp
		end
		logger.info "create_biz_and_admin(), Get all the memberships, OK!"
		all_ucs = rsp.body == nil ? { } : JSON.parse(rsp.body)

		# find the specific UC under which we want to create the small business UCs
		top_level_uc = find_member_by_property(all_ucs, 'name', @admin_level_collection)
		children_link = find_link_by_relation(top_level_uc, 'children')

		## step 2: post a representation of the user collection we
		##         want to make a new child of the top-level collection

		# create a Ruby hash representing our new user collection entity
		sb_uc = {
			'doc' => 'entity',
			'type' => 'user-collection',
			'properties' => {
				'name' => bizName
			}
		}

		# POST it to the 'children' relation we found above
		rsp = self.post(children_link, sb_uc)
		unless /^20/.match(rsp.code)
			logger.error  "create_biz_and_admin(),  when trying to create bussiness collection #{bizName}. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
			return rsp
		end
		logger.info "create_biz_and_admin(), Create small bussiness collection '#{bizName}',  OK!"
		sb_uc = rsp.body == nil ? { } : JSON.parse(rsp.body)

		logger.info "sb_uc: #{sb_uc.to_json}"

		###
		### goal 2: create a new administrator for the small business collection
		###

		## step 1: create the new user who is to become the administrator of
		##         the 'small business' collection

		# create a Ruby hash representing our new administrator
		sb_admin = {
			'doc' => 'entity',
			'type' => 'user',
			'properties' => {
				'emailAddress' => admin_email,
				'locale' => 'en-US',
				'login' => login,
				'credential' => pass,
				'spaceTotal' => quota,
			}
		}

		# POST it to the small business members collection
		members_link = find_link_by_relation(sb_uc, 'members')
		rsp = self.post(members_link, sb_admin)
		unless /^20/.match(rsp.code)
			logger.error  "create_biz_and_admin(),  when trying to create bussiness admin user. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
			return rsp
		end
		logger.info "create_biz_and_admin(), Create a admin user '#{login}', OK!"
		sb_admin = rsp.body == nil ? { } : JSON.parse(rsp.body)
		## step 2: make this new user an administrator of the previously-
		##         created collection

		logger.info "sb_admin: #{sb_admin.to_json}"
		return rsp

=begin
		# POST our newly-created user to the 'owners' relation
		owners_link = find_link_by_relation(sb_uc, 'owners')
		logger.info "owners_link: #{owners_link.to_json}"

		rsp = self.post(owners_link, sb_admin)  # no response for this one
		unless /^20/.match(rsp.code)
			logger.error  "create_biz_and_admin(), when trying to assign business owner. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
			return rsp
		end
		logger.info "create_biz_and_admin(), Assign user '#{login}' to small bussiness '#{bizName}' as an Admin (owner), OK!"

		#return the final response
		return rsp
=end
	end

	def assign_owner(bizName)
		if bizName.blank?
			logger.error "Execution error! The reason is at least one of the following params is not supplied to execute the API: bizName, quota, login, pass, admin_email. Please Check!"
			return
		end
		# retrieve our service's "home page"
		rsp = self.get()

		unless /^20/.match(rsp.code)
			logger.error  "assign_owner(), when trying to load login page. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
			return rsp
		end
		logger.info "assign_owner(), Load login page, OK!"
		homepage = rsp.body == nil ? { } : JSON.parse(rsp.body)

		# retrieve our administrator's user entity via the 'login' relation
		login_link = find_link_by_relation(homepage, 'login')

		logger.info "login_link: #{login_link.to_json}"
		logger.info "username: #{@username}"
		logger.info "password: #{@password}"
		logger.info "admin_level_collection: #{@admin_level_collection}"

		rsp = self.get(login_link)
		unless /^20/.match(rsp.code)
			logger.error  "assign_owner(), when trying to login as bussiness top level admin. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
			return rsp
		end
		logger.info "assign_owner(), Login as Top level Collection Admin, OK!"
		me = rsp.body == nil ? { } : JSON.parse(rsp.body)

		all_ucs_link = find_link_by_relation(me, 'memberships')
		logger.info "all_ucs_link: #{all_ucs_link.to_json}"

		rsp = self.get(all_ucs_link)
		unless /^20/.match(rsp.code)
			logger.error  "assign_owner(),  when trying to get memberships. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
			return rsp
		end
		logger.info "assign_owner(), Get all the memberships, OK!"
		all_ucs = rsp.body == nil ? { } : JSON.parse(rsp.body)

		biz = find_member_by_property(all_ucs, 'name', bizName)
		biz_link = find_link_by_relation(biz, 'self')
		logger.info "biz_link: #{biz_link.to_json}"

		biz_members_link = find_link_by_relation(biz, 'members')
		logger.info "biz_members_link: #{biz_members_link.to_json}"

		rsp = self.get(biz_members_link)
		unless /^20/.match(rsp.code)
			logger.error  "assign_owner(),  when trying to get members. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
		return  rsp
		end
		logger.info "assign_owner(), Get all the members,  OK!"
		all_members = rsp.body == nil ? { } : JSON.parse(rsp.body)
		logger.info "all_members: #{all_members.to_json}"

		#self_link = find_link_by_relation(all_members, 'members')
		members = all_members['members']
		member = members[0]
		member_property = member['properties']
		user_id = member_property['id']
		# create a Ruby hash representing our new administrator
		sb_admin = {
			'doc' => 'entity',
			'type' => 'user',
			'properties' => {
				'id' => user_id,
			}
		}
		logger.info "sb_admin: #{sb_admin.to_json}"

		# POST our newly-created user to the 'owners' relation
		owners_link = find_link_by_relation(biz, 'owners')
		logger.info "owners_link: #{owners_link.to_json}"

		rsp = self.post(owners_link, sb_admin)  # no response for this one
		unless /^20/.match(rsp.code)
			logger.error  "assign_owner(), when trying to assign business owner. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
			return rsp
		end
		logger.info "assign_owner(), Assign user to small bussiness '#{bizName}' as an Admin (owner), OK!"

		#return the final response
		return rsp
	end

      def create_user(bizName, user_login, pass, quota, email)

        if quota.blank? or user_login.blank? or pass.blank? or email.blank?
          logger.info "Execution error! The reason is at least one of the following params is not supplied to execute the API: quota, user_login, pass, email. Please Check!"
        return
        end

        logger.info "Calling function create_user(bizName, user_login, pass, quota, email), Parameters are (by function order): businessName(#{bizName}), user_login(#{user_login}), pass(#{pass}), quota(#{quota}), user_email(#{email})"
        ###
        ### goal 3: as the new administrator, create a new user
        ###

        ## step 1: login as the new administrator

        rsp = self.get()
        unless /^20/.match(rsp.code)
          logger.error  "create_user(),  when trying to load login page. (#{rsp.code}  #{rsp.message}), #{rsp.body} Failed!"
        return  rsp
        end
        logger.info  "create_user(),  load login page, OK!"
        homepage = rsp.body == nil ? { } : JSON.parse(rsp.body)
        login_link = find_link_by_relation(homepage, 'login')

		logger.info "login_link: #{login_link.to_json}"
		logger.info "username: #{@username}"
		logger.info "password: #{@password}"
		logger.info "admin_level_collection: #{@admin_level_collection}"

        rsp = self.get(login_link)
        unless /^20/.match(rsp.code)
          logger.error  "create_user(),  when trying to login as admin. (#{rsp.code}  #{rsp.message} #{rsp.body}),  Failed!"
        return  rsp
        end
        logger.info "create_user(), Login as user, OK!"
        me = rsp.body == nil ? { } : JSON.parse(rsp.body)

        #
        # ## step 2: find the entity representing the small business UC
        #
        all_ucs_link = find_link_by_relation(me, 'memberships')
        rsp = self.get(all_ucs_link)
        unless /^20/.match(rsp.code)
          logger.error  "create_user(),  when trying to get memberships. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info "create_user(), Get all the memberships,  OK!"
        all_ucs = rsp.body == nil ? { } : JSON.parse(rsp.body)

        sb_uc = find_member_by_property(all_ucs, 'name', bizName)
        ## step 3: create the new user by POSTing a representation
        ##         to the 'members' relation of our new UC

        # create a Ruby hash representing our new regular user
        sb_user =
        {
          'doc' => 'entity',
          'type' => 'user',
          'properties' =>
          {
            'emailAddress' => email,
            'locale' => 'en-US',
            'login' => user_login,
            'credential' => pass,
            'spaceTotal' => quota,
          }
        }

        # POST it to the small business members collection
        members_link = find_link_by_relation(sb_uc, 'members')
        rsp = self.post(members_link, sb_user)
        unless /^20/.match(rsp.code)
          logger.error  "create_user(), when trying to create user by post. (#{rsp.code}  #{rsp.message} #{rsp.body}), Failed!"
        return  rsp
        end
        logger.info "create_user(), Create a user '#{user_login}', OK!"

        # #send email to user
        # admin_url = "http://core5qa.digidatagrid.com/current/admin/Core/Login.aspx"
        # user_url = "http://core5qa.digidatagrid.com/current/obw/Core/Login.aspx"
        # Notifier.deliver_cloud_storage_created(user_login, pass, email, admin_url, user_url)
        # logger.info "Send an email to '#{email}' for user '#{user_login}' of Small Bussiness '#{bizName}' OK!"

        #return the final response
        return  rsp
      end

    end
  end
end
