require 'inherited_resources'

class Admin::ResourcesController < ApplicationController
  inherit_resources

  layout "admin"

  before_filter :require_user
  before_filter :admin_only
  
  helper_method :resource_class_as_sym

  protected
  def resource_class_as_sym
    resource_class.name.underscore.to_sym
  end

  def resource_sort_order
    "#{ resource_class.name.tableize }.#{ sort_order(:default => "ascending") }"
  end

  def per_page; 100500; end

  def sphinx_filters; {}; end

  def collection

    get_collection_ivar || set_collection_ivar(
      if params[:search].blank?
        end_of_association_chain.paginate(:page => params[:page], :per_page => per_page, :order => resource_sort_order)
      else
        end_of_association_chain.search(params[:search], :with => sphinx_filters, :page => params[:page], :order => "name ASC", :star => true)
      end
    )
  end
#  def per_page
#    20
#  end
end
