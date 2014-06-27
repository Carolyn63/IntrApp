# encoding: utf-8

class ApplicationBinFileUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick
  # Choose what kind of storage to use for this uploader
  storage :file
  #     storage :s3

  def store_dir
    #@logger = Tools::ApiLogger.new :name => options[:log_name] || "mobiletribe"
    Rails.root.join "files/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Add a white list of extensions which are allowed to be uploaded,
  # for images you might use something like this:
  #     def extension_white_list
  #       %w(jpg jpeg gif png)
  #     end

  # Override the filename of the uploaded files
  #     def filename
  #       "something.jpg" if original_filename
  #     end

end
