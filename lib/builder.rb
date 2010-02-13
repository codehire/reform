module Reform

  class Builder < ActionView::Helpers::FormBuilder

    include Helpers
    
    def field_settings(method, options = {}, tag_value = nil)
      field_name = "#{@object_name}_#{method.to_s}"
      default_label = humanized_label_for(method, tag_value)
      required = @template.content_tag(:sup, "*") if options[:required]
      label = "#{required}#{options[:label] ? options.delete(:label) : default_label}"
      row_class = options.delete(:row_class) || ''
      row_class << " required" if options.delete(:required)
      label_class = options.has_key?(:label_class) ? options.delete(:label_class) : ''
      [field_name, label, {}.merge(options), row_class, label_class]
    end
    
    def text_field(method, options = {})
      field_name, label, options, row_class, label_class = field_settings(method, options)
      wrapping("text", method, field_name, label, row_class, label_class, super, options)
    end
    
    def file_field(method, options = {})
      field_name, label, options, row_class, label_class = field_settings(method, options)
      wrapping("file", method, field_name, label, row_class, label_class, super, options)
    end
    
    def datetime_select(method, options = {})
      field_name, label, options, row_class, label_class = field_settings(method, options)
      wrapping("datetime", method, field_name, label, row_class, label_class, super, options)
    end

    def date_select(method, options = {})
      field_name, label, options, row_class, label_class = field_settings(method, options)
      wrapping("date", method, field_name, label, row_class, label_class, super, options)
    end
    
    def radio_button(method, tag_value, options = {})
      field_name, label, options, row_class, label_class = field_settings(method, options)
      wrapping("radio", method, field_name, label, row_class, label_class, super, options)
    end
      
    def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      field_name, label, options, row_class, label_class = field_settings(method, options)
      check_box_label = options.delete(:check_box_label) || nil
      options[:field_class] = options.delete(:class)
      actual_input = super
      actual_input = "<label class=\"field-label-inline\">#{actual_input}#{check_box_label}</label>" if check_box_label
      wrapping("check-box", method, field_name, label, row_class, label_class, actual_input, options)
    end
    
    def select(method, choices, options = {}, html_options = {})
      field_name, label, options, row_class, label_class = field_settings(method, options)
      wrapping("select", method, field_name, label, row_class, label_class, super, options)
    end

    def time_zone_select(method, options = {}, html_options = {})
      field_name, label, options, row_class, label_class = field_settings(method, options)
      wrapping("time-zone-select", method, field_name, label, row_class, label_class, super, options)    
    end
    
    def password_field(method, options = {})
      field_name, label, options, row_class, label_class = field_settings(method, options)
      wrapping("password", method, field_name, label, row_class, label_class, super, options)
    end

    def text_area(method, options = {})
      field_name, label, options, row_class, label_class = field_settings(method, options)
      wrapping("textarea", method, field_name, label, row_class, label_class, super, options)
    end
        
    def submit(method, options = {})
      field_name, label, options, row_class, label_class = field_settings(method, options.merge( :label => "&nbsp;"))
      wrapping("submit", method, field_name, label, row_class, label_class, super, options)
    end
    
    def location_select(method, options ={})
      field_name, label, options, row_class, label_class = field_settings(method, options.merge( :label => "&nbsp;"))
      wrapping("text", method, field_name, label, row_class, label_class, super, options)
    end    
    
    def choice(method, options={})
      field_name, label, options, row_class, label_class = field_settings(method, options)
      wrapping("choice", method, field_name, label, row_class, label_class, option_switch(method, options), options)
    end

    def checkboxes(method, choices, options={})
      check_box_group(method, choices, options)
    end

    def check_boxes(method, choices, options={})
      check_box_group(method, choices, options)
    end

    def radio_buttons(method, choices, options={})
      radio_button_group(method, choices, options)
    end

    def submit_and_cancel(submit_name, cancel_name, options = {})
      submit_button = @template.submit_tag(submit_name, options)
      cancel_button = @template.submit_tag(cancel_name, options)
      wrapping("submit", nil, nil, "", submit_button+cancel_button, options)
    end

    def radio_button_group(method, values, options = {})
      field_name, label, options, row_class, label_class = field_settings(method, options)
      class_name = options.delete(:class)
      selections = []
      values.each do |value|
        if value.is_a?(Hash)
          tag_value = value[:value]
          item_label = value[:label]
          help = value.delete(:help)
          if value.has_key?(:checked)
            checked = value.delete(:checked)
          end
        else
          tag_value = value
          value_text = value
        end
        checked ||= (@object.send(method) == tag_value) if @object
        radio_button = @template.radio_button(@object_name, method, tag_value, options.merge(:object => @object, :help => help, :checked => checked))
        selections << boolean_field_wrapper(
                          radio_button, "#{@object_name}_#{method.to_s}",
                          tag_value, item_label, nil, class_name)
      end
      semantic_group(method, "radio", field_name, label, row_class, label_class, selections, options)    
    end
    
    def check_box_group(method, values, options = {})
      field_name, label, options, row_class, label_class = field_settings(method, options)
      label = nil if options[:hide_label]
      selections = []
      name = "#{@object_name}[#{method}][]"
      class_name = options.delete(:class)
      selections << @template.hidden_field_tag(name, nil) if options.delete(:require_hidden)
      values.each do |value|
        if value.is_a?(Hash)
          checked_value = value[:checked_value]
          unchecked_value = value[:unchecked_value]
          value_text = value[:label]
          help = value.delete(:help)
        elsif value.is_a?(Array)
          checked_value = value[1]
          unchecked_value = nil
          value_text = value[0]
          help = ''
        else
          checked_value = 1
          unchecked_value = 0
          value_text = value
        end
        id = "#{@object_name}_#{method}_#{checked_value}"
        id = id.downcase.gsub(/[\[\]]/, '_').gsub(/\]$/, '').gsub(/__/, '_')
        check_box = @template.check_box_tag(name, checked_value, (@object ? @object.send(method).try(:include?, checked_value) : nil), :id => id)
        selections << boolean_field_wrapper(
                          check_box, "#{@object_name}_#{method.to_s}",
                          checked_value, value_text, nil, class_name)
      end
      semantic_group(method, "check-box", field_name, label, row_class, label_class, selections, options)
    end

  end

end
