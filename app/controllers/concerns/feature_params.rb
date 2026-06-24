module FeatureParams
  extend ActiveSupport::Concern

  private

  def build_features_params(features_param, type:, scope:)
    features_param ||= {}
    type = type.presence || "residential"

    PropertyFeatureCatalog.definitions_for(type, scope: scope).each_with_object({}) do |definition, result|
      if definition.data_type == :boolean
        result[definition.key] = features_param.key?(definition.key) && ActiveModel::Type::Boolean.new.cast(features_param[definition.key])
      elsif features_param.key?(definition.key)
        result[definition.key] = features_param[definition.key]
      end
    end
  end
end
