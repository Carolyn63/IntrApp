class Devicefication < ActiveRecord::Base
	belongs_to :application
	belongs_to :device, :counter_cache => :applications_count

	validates_presence_of :application
	validates_presence_of :device
	#validates_presence_of :bin_file
	validates_uniqueness_of :device_id, :scope => :application_id
	#validate :screen_and_bin_file_size_validation

	mount_uploader :bin_file, ApplicationBinFileUploader

	before_destroy do |record|
		record.remove_bin_file!
	end
end
