require 'uri'

class HelpUrl < ActiveRecord::Base

  validates_presence_of :name, :portal_url, :help_url
  validates_format_of   :help_url, :with => /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*((\.|\:)([a-z]{2,5}|[0-9]+))(([0-9]{1,5})?\/.*)?$)/

  before_save :parse_portal_url

  by_whatever

  def self.find_help_url params
    urls = HelpUrl.find_all_by_action_name_and_controller_name(params[:action], params[:controller])
    url = if urls.size > 1
      find_url = urls.find do |u|
        !u.url_params.blank? && (params[:url_params].include?(u.url_params) || u.url_params.include?(params[:url_params]))
      end unless params[:url_params].blank?
      find_url || urls.find{|u| u.url_params.blank?} || urls.first
    else
      urls.first
    end
    url.blank? ? nil : url.help_url
  end

  private
  
  def parse_portal_url
    begin
      uri = URI.parse(self.portal_url)
      recognize_path = ActionController::Routing::Routes.recognize_path(uri.path, :method => :get)
      raise if recognize_path.blank?
      self.action_name = recognize_path[:action]
      self.controller_name = recognize_path[:controller]
      self.url_params = uri.query.to_s

      unless HelpUrl.find_by_action_name_and_controller_name_and_url_params(self.action_name, self.controller_name, self.url_params).blank?
        self.errors.add(:portal_url, I18n.t("models.help_url.error_uniq_of_url"))
        return false
      end
      
#      recognize_path.each {|k,v| recognize_path[k] = ":#{k.to_s}" if k != :action && k != :controller}
#      self.portal_url = ActionController::Routing::Routes.generate(recognize_path)

      self.portal_url = self.portal_url.split(/\/\d+\//).join("/:id/") 
    rescue
      self.errors.add(:portal_url, I18n.t("models.help_url.error_parse_portal_url"))
      return false
    end
  end

end
