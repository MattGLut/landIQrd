module HasTypedFeatures
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_features
    before_validation :strip_disallowed_feature_keys
    validate :validate_features
  end

  def feature_value(key)
    features[key.to_s]
  end

  def set_feature(key, value)
    self.features = features.merge(key.to_s => value)
  end

  def present_features
    PropertyFeatureCatalog.definitions_for(feature_catalog_type, scope: feature_catalog_scope).filter_map do |definition|
      value = feature_value(definition.key)
      next if value.blank? && value != false

      { definition: definition, value: value }
    end
  end

  private

  def normalize_features
    self.features = {} if features.nil?
    allowed = PropertyFeatureCatalog.keys_for(feature_catalog_type, scope: feature_catalog_scope)

    allowed.each do |key|
      definition = PropertyFeatureCatalog.definition(feature_catalog_type, feature_catalog_scope, key)
      next unless definition

      raw = features[key]
      next if raw.nil? || raw == ""

      features[key] = coerce_feature_value(definition, raw)
    end
  end

  def strip_disallowed_feature_keys
    allowed = PropertyFeatureCatalog.keys_for(feature_catalog_type, scope: feature_catalog_scope)
    self.features = features.slice(*allowed)
  end

  def validate_features
    PropertyFeatureCatalog.definitions_for(feature_catalog_type, scope: feature_catalog_scope).each do |definition|
      value = feature_value(definition.key)

      if definition.required && value.blank? && value != false
        errors.add(:features, "#{definition.label} is required")
        next
      end

      next if value.blank? && value != false

      validate_feature_value(definition, value)
    end
  end

  def coerce_feature_value(definition, raw)
    case definition.data_type
    when :boolean
      ActiveModel::Type::Boolean.new.cast(raw)
    when :integer
      raw.to_i
    when :decimal
      BigDecimal(raw.to_s)
    when :enum
      raw.to_s
    else
      raw.to_s
    end
  end

  def validate_feature_value(definition, value)
    case definition.data_type
    when :boolean
      errors.add(:features, "#{definition.label} must be true or false") unless value.in?([ true, false ])
    when :integer
      errors.add(:features, "#{definition.label} must be a whole number") unless value.is_a?(Integer)
    when :decimal
      unless decimal_value?(value)
        errors.add(:features, "#{definition.label} must be a number")
      end
    when :enum
      errors.add(:features, "#{definition.label} is not a valid option") unless definition.options.include?(value.to_s)
    end
  end

  def decimal_value?(value)
    return true if value.is_a?(BigDecimal)
    return true if value.is_a?(Integer) || value.is_a?(Float)

    BigDecimal(value.to_s)
    true
  rescue ArgumentError, TypeError
    false
  end
end
