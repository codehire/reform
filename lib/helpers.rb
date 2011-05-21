 module Reform

  module Helpers
        
    def buttons(options = {}, &block)
      to_return = []
      to_return << %Q{<div class="field field-buttons #{options[:row_class]}">}
      to_return << %Q{<div class="field-label #{options[:label_class]}">&nbsp;</div>}
      to_return << %Q{<div class="field-inner">}
      to_return << @template.capture(&block)
      to_return << %Q{<div class="required_description"><span class="required">*</span> Required field</div>} if options.has_key?(:required_description) && options[:required_description] == true
      to_return << %Q{</div>}
      to_return << %Q{</div>}
      @template.concat to_return.join('')
    end    
    
    def wrapping(type, method, field_name, label, row_class, label_class, field, options = {})
      unless @in_row
        style = options[:hide] ? 'display: none' : ''
        label = label.strip
        label = label.blank? ? "&nbsp;" : label
        field_class = options.delete(:field_class)
        field_id = options[:id] || "#{@object_name}_#{method.to_s}"
        field_id = field_id.gsub(/[\[\]]/, '_').gsub(/\]$/, '').gsub(/__/, '_')
        row_id = field_name.downcase.gsub(/[\[\]]/, '_').gsub(/\]$/, '').gsub(/__/, '_')
        to_return = []
        to_return << %Q{<div id="field_#{row_id}" class="field field-#{type} #{row_class}" style="#{style}">}
        to_return << %Q{<div class="field-label #{label_class}">}
        to_return << %Q{<label for="#{row_id}">#{label}</label>} unless ["radio","check", "submit"].include?(type)
        to_return << %Q{</div>}
        to_return << %Q{<div class="field-inner #{field_class}">}
        to_return << field
        to_return << inline_errors(method) if @object.respond_to?(:errors)
        to_return << %Q{<label for="#{field_name}">#{label}</label>} if ["radio","check"].include?(type)    
        to_return << inline_help(options[:help], field_class)
        to_return << %Q{</div>}
        to_return << %Q{</div>}
        to_return << %Q{<script type="text/javascript">$(document).ready(function() { $('##{field_id}').autogrow({ minHeight: $('##{field_id}').height() }); });</script>} if options[:height] == :auto
        return to_return
      else
        field
      end
    end

    def remote_button(method, options = {})
      options[:id]      = "#{options[:id] || rand(10000)}_button"
      text              = @template.content_tag(:span, (options[:label] || method.to_s.humanize.titleize))
      image             = image_tag("ajax/button.gif", :id=>"#{options[:id]}_spinner", :style=>"display:none")
      active_text       = t("labels.saving")      
      options[:onclick] = "$(this).find('img').show();"; 
      options[:onclick] += "return FormHelpers.buttons.click(this);" unless options[:type] == :button
      options[:type]    ||= :submit
      @template.content_tag(:button, image+text, :id=>options[:id], :onclick => options[:onclick], :value => method, :class => "button #{options[:class] || ''} #{(method || '').to_s.downcase.underscore}", :type => options[:type])      
    end


    def button(method, options = {}) 
      options[:onclick] ||= "return FormHelpers.buttons.click(this);"
      options[:onclick] = nil if options[:type] == :button
      options[:type] ||= :submit
      options[:value] ||= method
      options[:class] = "button #{options[:class] || ''} #{(method || '').to_s.downcase.underscore}" 
      @template.content_tag(:button, options[:label] || method.to_s.humanize.titleize, options)
    end
    
    def option_switch(id, opts={})
      ["yes", "no"].map do |option|
        @template.content_tag(:div, @template.radio_button_tag(id, option, ((option == "yes" and opts[:selected] == true) or (option == "no" and opts[:selected] == false))), :class=>"option #{option}", :onclick => 'jQuery(this).find("input").attr("checked", true)')
      end
    end

    def row(method, options = {}, &block)
      label      = options[:label] || method
      field_name = "#{@object_name}_#{method.to_s}"
      id         = options[:id] || "field_#{field_name.downcase}"
      style      = options[:hide] ? 'display: none' : ''
      required = @template.content_tag(:sup, "*") if options[:required]
      errors = inline_errors(method) if @object.respond_to?(:errors)
      id = id.downcase.gsub(/[\[\]]/, '_').gsub(/\]$/, '').gsub(/__/, '_')
      @in_row    = true
      @template.concat <<-HTML
        <div id="#{id}" class="field field-custom #{options[:row_class]}" style="#{style}">
          <div class="field-label #{options[:label_class]}">
            <label for="#{method}">#{required}#{label.to_s}</label>
          </div>
          <div class="field-inner #{options[:field_class]}">
            #{@template.capture(&block)}
            #{errors}
            #{inline_help(options[:help])}
          </div>
        </div>
      HTML
      @in_row = false
    end

    def inline_errors(method, options = {})
      errors = @object.respond_to?(:errors) ? @object.errors.on(method).to_a : []
      @template.content_tag(:div, errors.join('<br />'), :class => 'field-errors') unless errors.empty?
    end

    def inline_help(help, class_name = nil)
      class_name = class_name || ""
      %Q{<div class="field-help #{class_name}">#{help}</div>} if help
    end

    def semantic_group(method, type, field_name, label, row_class, label_class, fields, options = {})
      id = "field_#{field_name.to_s.downcase}"
      id = id.downcase.gsub(/[\[\]]/, '_').gsub(/\]$/, '').gsub(/__/, '_')
      label_id = field_name.downcase.gsub(/[\[\]]/, '_').gsub(/\]$/, '').gsub(/__/, '_')
      help = inline_help(options[:help], options[:field_class]) if options[:help]
      to_return = []
      to_return << %Q{<div id="#{id}" class="field field-#{type} #{row_class}">}
      to_return << %Q{<div class="field-label #{label_class}">}
      to_return << %Q{<label for="#{label_id}">#{label}</label>}
      to_return << %Q{</div>}
      to_return << %Q{<div class="field-inner #{options[:field_class]}">}    
      to_return << fields.join
      to_return << "<br style='clear: both'/>#{inline_errors(method)}" if @object.try(:errors).try(:any?)
      to_return << help
      to_return << %Q{</div>}
      to_return << %Q{</div>}
      return to_return.join("")
    end

    def boolean_field_wrapper(input, name, value, text, help = nil, class_name = nil)
      id = "label_#{name}_#{value}".downcase.gsub(/[\[\]]/, '_').gsub(/\]$/, '').gsub(/__/, '_')
      @template.content_tag(:label, "#{input} #{text}", :id => id, :class=>"#{class_name} input")
    end
    
    def humanized_label_for(method, tag_value=nil)
      if tag_value.nil?
        if @object && @object.class.respond_to?(:human_attribute_name)
          @object.class.human_attribute_name(method.to_s)
        else
          method.to_s.humanize
        end
      else
        tag_value.to_s.humanize
      end
    end
  end

end
