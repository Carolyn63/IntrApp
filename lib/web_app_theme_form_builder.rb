require 'action_view/helpers/form_helper'

class WebAppThemeFormBuilder < ActionView::Helpers::FormBuilder

  (field_helpers.map(&:to_s) - %w(radio_button hidden_field fields_for) +
        %w(date_select)).each do |selector|
    src = <<-END_SRC
    def #{selector}(field, options = {})
      @template.content_tag(:div, label_for_field(field, options) + super(field, options.except(:label)), :class => 'group')
    end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end

  def select(field, choices, options = {}, html_options = {})
    label_for_field(field, options) + super(field, choices, options, html_options.except(:label))
  end

  # Returns a label tag for the given field
  def label_for_field(field, options = {})
      #return ''.html_safe if options.delete(:no_label)
      # text = options[:label].is_a?(Symbol) ? l(options[:label]) : options[:label]
      # text ||= l(("field_" + field.to_s.gsub(/\_id$/, "")).to_sym)
      return "" if options[:label] == false
      text = field.to_s.humanize
      text += @template.content_tag("span", " *", :class => "required") if options.delete(:required)
      @template.content_tag("label", text,
                                     :class => "label #{ (@object && @object.errors[field] ? 'error' : nil) }",
                                     :for => (@object_name.to_s + "_" + field.to_s))
  end
end
