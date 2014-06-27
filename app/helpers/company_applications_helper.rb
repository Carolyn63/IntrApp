module CompanyApplicationsHelper

  def resource_sort_order
    "#{ resource_class.name.tableize }.#{ sort_order(:default => "ascending") }"
  end
    def pluralized_resource_class_name
    resource_class.name.pluralize
  end

  def comp_error_messages_for_resource
    error_messages_for resource_class.name.underscore.to_sym
  end

  def comp_web_app_theme_form_for(record_or_name_or_array, *args, &proc)
    options = args.extract_options!
    form_for(record_or_name_or_array, *(args << options.merge(:builder => WebAppThemeFormBuilder)), &proc)
  end
end
