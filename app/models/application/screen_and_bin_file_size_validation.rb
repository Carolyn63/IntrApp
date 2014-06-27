module Application::ScreenAndBinFileSizeValidation

  def self.included(base)
    base.send :include, InstanceMethods
  end

  module InstanceMethods

    protected
    def screen_and_bin_file_size_validation
      max = 10
      %w{screenshot0 screenshot1 screenshot2}.each do |f|
        image = self.send(f.to_sym)
        errors.add(f.to_sym, I18n.t('activerecord.errors.messages.size_too_big', :size => max)) if image.present? && image.size > max.megabytes.to_i
      end

      image = self.bin_file
      errors.add(:bin_file, I18n.t('activerecord.errors.messages.size_too_big', :size => 30)) if image.present? && image.size > 30.megabytes.to_i
    end
  end

end
