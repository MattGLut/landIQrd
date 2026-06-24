module FeaturesHelper
  def property_type_options
    Property.property_types.keys.map { |type| [ PropertyFeatureCatalog.type_label(type), type ] }
  end

  def unit_type_options(property)
    [ [ "Same as property (#{PropertyFeatureCatalog.type_label(property.property_type)})", "" ] ] +
      Property.property_types.keys.map { |type| [ PropertyFeatureCatalog.type_label(type), type ] }
  end

  def property_type_badge(type)
    colors = {
      "residential" => :blue,
      "commercial" => :indigo,
      "undeveloped" => :yellow
    }
    status_badge(PropertyFeatureCatalog.type_label(type), colors.fetch(type.to_s, :gray))
  end

  def feature_field_name(scope, key)
    "#{scope}[features][#{key}]"
  end

  def feature_field_id(scope, key)
    "#{scope}_features_#{key}"
  end

  def render_feature_field(form_scope, record, definition)
    key = definition.key
    value = record.feature_value(key)
    name = feature_field_name(form_scope, key)
    id = feature_field_id(form_scope, key)
    label_class = "block text-sm font-medium text-slate-500 dark:text-slate-400"

    case definition.data_type
    when :boolean
      tag.div class: "flex items-center gap-2" do
        safe_join([
          check_box_tag(name, "1", value == true, id: id, class: "rounded border-slate-300 text-brand-600 focus:ring-brand-500 dark:border-slate-600 dark:bg-slate-800"),
          label_tag(id, definition.label, class: label_class)
        ])
      end
    when :enum
      tag.div do
        safe_join([
          label_tag(id, definition.label, class: label_class),
          select_tag(
            name,
            options_for_select([ [ "—", "" ] ] + definition.options.map { |option| [ option.humanize, option ] }, value),
            id: id,
            class: form_input_class
          )
        ])
      end
    when :integer, :decimal
      tag.div do
        safe_join([
          label_tag(id, definition.label, class: label_class),
          number_field_tag(
            name,
            value,
            id: id,
            step: definition.data_type == :decimal ? 0.1 : 1,
            class: form_input_class
          )
        ])
      end
    else
      tag.div do
        safe_join([
          label_tag(id, definition.label, class: label_class),
          text_field_tag(name, value, id: id, class: form_input_class)
        ])
      end
    end
  end

  def format_feature_value(definition, value)
    case definition.data_type
    when :boolean
      value ? "Yes" : "No"
    when :enum
      value.to_s.humanize
    else
      value.to_s
    end
  end
end
