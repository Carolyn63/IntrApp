# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120420143928) do

  create_table "application_types", :force => true do |t|
    t.string   "name",                              :null => false
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "applications_count", :default => 0, :null => false
  end

  create_table "applications", :force => true do |t|
    t.string   "name",                                       :null => false
    t.string   "logo"
    t.text     "description"
    t.float    "price"
    t.string   "provider"
    t.string   "external_url"
    t.string   "bin_file"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "screenshot0"
    t.string   "screenshot1"
    t.string   "screenshot2"
    t.boolean  "delta",                    :default => true, :null => false
    t.integer  "status",                   :default => 0,    :null => false
    t.integer  "approved_companies_count", :default => 0,    :null => false
    t.integer  "departments_count",        :default => 0,    :null => false
    t.integer  "employees_count",          :default => 0,    :null => false
    t.integer  "approved_employees_count", :default => 0,    :null => false
  end

  create_table "audits", :force => true do |t|
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.string   "name"
    t.integer  "status",               :default => 1, :null => false
    t.integer  "parent_id"
    t.text     "description"
    t.text     "comment"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "messages"
    t.text     "auditable_attributes"
  end

  create_table "categories", :force => true do |t|
    t.string   "name",                              :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.integer  "applications_count", :default => 0, :null => false
  end

  create_table "categorizations", :force => true do |t|
    t.integer "application_id", :null => false
    t.integer "category_id",    :null => false
  end

  create_table "companies", :force => true do |t|
    t.string   "name",                            :default => "",   :null => false
    t.string   "address",                         :default => "",   :null => false
    t.string   "city",                            :default => "",   :null => false
    t.string   "phone",                           :default => "",   :null => false
    t.string   "company_type"
    t.integer  "privacy",                         :default => 0,    :null => false
    t.string   "industry",                        :default => "",   :null => false
    t.text     "description"
    t.string   "size",                            :default => "",   :null => false
    t.string   "team",                            :default => "",   :null => false
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "country_phone_code",              :default => "+1"
    t.string   "perishable_token",                                  :null => false
    t.boolean  "delta",                           :default => true, :null => false
    t.string   "website",                         :default => "",   :null => false
    t.string   "twitter",                         :default => "",   :null => false
    t.string   "facebook",                        :default => "",   :null => false
    t.integer  "ondeego_company_id"
    t.integer  "is_ondeego_connect", :limit => 1, :default => 0,    :null => false
  end

  create_table "companifications", :force => true do |t|
    t.integer  "application_id",                         :null => false
    t.integer  "company_id",                             :null => false
    t.string   "status",         :default => "approved", :null => false
    t.datetime "requested_at"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "department_applications", :force => true do |t|
    t.integer "application_id", :null => false
    t.integer "department_id",  :null => false
  end

  create_table "departments", :force => true do |t|
    t.string   "name",        :default => "", :null => false
    t.text     "description"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "devicefications", :force => true do |t|
    t.integer "application_id", :null => false
    t.integer "device_id",      :null => false
  end

  create_table "devices", :force => true do |t|
    t.string  "name",                              :null => false
    t.text    "description",                       :null => false
    t.integer "applications_count", :default => 0, :null => false
    t.integer "employees_count",    :default => 0, :null => false
  end

  create_table "employee_applications", :force => true do |t|
    t.integer  "application_id",                         :null => false
    t.integer  "employee_id",                            :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status",         :default => "approved", :null => false
    t.datetime "requested_at"
  end

  create_table "employee_devices", :force => true do |t|
    t.integer  "employee_id", :null => false
    t.integer  "device_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "employees", :force => true do |t|
    t.integer  "user_id"
    t.integer  "company_id"
    t.string   "status",                                  :default => "pending", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "phone"
    t.string   "job_title",                               :default => "",        :null => false
    t.string   "perishable_token",                                               :null => false
    t.string   "invitation_token"
    t.datetime "published_at"
    t.string   "company_email"
    t.string   "company_email_password"
    t.integer  "is_sogo_connect",         :limit => 1,    :default => 0,         :null => false
    t.integer  "department_id"
    t.integer  "is_mobile_tribe_connect", :limit => 1,    :default => 0,         :null => false
    t.integer  "ondeego_user_id"
    t.string   "oauth_token"
    t.string   "oauth_secret",            :limit => 1024
    t.integer  "is_ondeego_connect",      :limit => 1,    :default => 0,         :null => false
  end

  create_table "friendships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "friend_id"
    t.string   "status",        :default => "pending", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "friendship_id", :default => 0,         :null => false
    t.datetime "published_at"
  end

  create_table "help_urls", :force => true do |t|
    t.string   "name",            :default => "", :null => false
    t.string   "portal_url",      :default => "", :null => false
    t.string   "help_url",        :default => "", :null => false
    t.string   "action_name",     :default => "", :null => false
    t.string   "controller_name", :default => "", :null => false
    t.string   "url_params",      :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "typizations", :force => true do |t|
    t.integer "application_id",      :null => false
    t.integer "application_type_id", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "login",                                                  :null => false
    t.string   "email",                                                  :null => false
    t.string   "crypted_password",                                       :null => false
    t.string   "password_salt",                                          :null => false
    t.string   "persistence_token",                                      :null => false
    t.string   "single_access_token",                                    :null => false
    t.string   "perishable_token",                                       :null => false
    t.integer  "login_count",                          :default => 0,    :null => false
    t.integer  "failed_login_count",                   :default => 0,    :null => false
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "firstname",                            :default => "",   :null => false
    t.string   "lastname",                             :default => "",   :null => false
    t.string   "user_password",                        :default => "",   :null => false
    t.integer  "privacy",                              :default => 0,    :null => false
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.integer  "friendship_notification", :limit => 1, :default => 1,    :null => false
    t.string   "mobile_tribe_login",                   :default => "",   :null => false
    t.string   "mobile_tribe_password",                :default => "",   :null => false
    t.integer  "mobile_tribe_user_state",              :default => 0,    :null => false
    t.string   "address",                              :default => "",   :null => false
    t.string   "phone",                                :default => "",   :null => false
    t.string   "cellphone",                            :default => "",   :null => false
    t.string   "age",                                  :default => "",   :null => false
    t.string   "sex",                                  :default => "",   :null => false
    t.string   "site",                                 :default => "",   :null => false
    t.text     "description"
    t.integer  "role",                                 :default => 1,    :null => false
    t.integer  "status",                               :default => 0,    :null => false
    t.string   "job_title",                            :default => "",   :null => false
    t.string   "city",                                 :default => "",   :null => false
    t.string   "state",                                :default => "",   :null => false
    t.string   "country",                              :default => "",   :null => false
    t.boolean  "active",                               :default => true, :null => false
    t.boolean  "delta",                                :default => true, :null => false
  end

end
