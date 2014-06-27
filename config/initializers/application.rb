require 'digest/md5'

require "lib/tools/filter_error_messages"
require "lib/services/act_as_services_delete_audit"

ActiveRecord::Base.send :include, Tools::FilterErrorMessages
ActiveRecord::Base.send :include, Services::ActAsServicesDeleteAudit
