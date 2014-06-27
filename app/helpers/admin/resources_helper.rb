module Admin::ResourcesHelper
  def pluralized_resource_class_name
    resource_class.name.pluralize
  end

  def error_messages_for_resource
    error_messages_for resource_class.name.underscore.to_sym
  end

  def web_app_theme_form_for(record_or_name_or_array, *args, &proc)
    options = args.extract_options!
    form_for(record_or_name_or_array, *(args << options.merge(:builder => WebAppThemeFormBuilder)), &proc)
  end

  # CRUD
  def link_to_collection
    link_to "#{t("web-app-theme.list", :default => "List")}", collection_path
  end

  def link_to_new_resource
    link_to "#{t("web-app-theme.new", :default => "New")}", new_resource_path
  end

  def link_to_show(resource)
    link_to "#{t("web-app-theme.show", :default => "Show")}", resource_path(resource)
  end

  def link_to_edit(resource)
    link_to "#{t("web-app-theme.edit", :default => "Edit")}", edit_resource_path(resource)
  end

  def link_to_delete(resource)
    link_to "#{t("web-app-theme.edit", :default => "Delete")}", resource_path(resource), :method => "delete", :confirm => 'Are you sure?'
  end
end
