class Unit < ApplicationRecord
  include HasTypedFeatures

  belongs_to :property

  has_many :leases, dependent: :destroy
  has_many :work_orders, dependent: :destroy
  has_many :lease_invitations, dependent: :destroy

  enum :unit_type, { residential: 0, commercial: 1, undeveloped: 2 }, prefix: true, validate: { allow_nil: true }

  validates :label, presence: true
  validates :bedrooms, :bathrooms, presence: true, if: :residential_effective_type?
  validates :acreage, presence: true, numericality: { greater_than: 0 }, if: :undeveloped_effective_type?

  before_validation :clear_irrelevant_scalar_fields
  before_validation :normalize_unit_type

  delegate :landlord, to: :property

  def full_label
    "#{property.name} · #{label}"
  end

  def effective_type
    unit_type || property&.property_type || "residential"
  end

  def effective_type_label
    PropertyFeatureCatalog.type_label(effective_type)
  end

  def summary_line
    case effective_type
    when "residential"
      [ bedrooms && "#{bedrooms} bd", bathrooms && "#{format_count(bathrooms)} ba", square_feet && "#{square_feet} sqft" ].compact.join(" \u00b7 ")
    when "commercial"
      parts = []
      parts << feature_value("use_class")&.humanize if feature_value("use_class").present?
      parts << "#{square_feet} sqft" if square_feet.present?
      parts << "#{feature_value('parking_spaces')} parking" if feature_value("parking_spaces").present?
      parts.join(" \u00b7 ")
    when "undeveloped"
      parts = []
      parts << "#{acreage} acres" if acreage.present?
      parts << feature_value("zoning") if feature_value("zoning").present?
      utilities = %w[water sewer electric gas].select { |utility| feature_value("#{utility}_hookup") }
      parts << utilities.join("/") if utilities.any?
      parts.join(" \u00b7 ")
    else
      ""
    end
  end

  def current_tenant
    active_lease&.tenant
  end

  def active_lease
    leases.find_by(status: :active)
  end

  private

  def residential_effective_type?
    effective_type == "residential"
  end

  def undeveloped_effective_type?
    effective_type == "undeveloped"
  end

  def normalize_unit_type
    self.unit_type = nil if unit_type.blank?
  end

  def clear_irrelevant_scalar_fields
    case effective_type
    when "residential"
      self.acreage = nil
    when "commercial"
      self.bedrooms = nil
      self.bathrooms = nil
      self.acreage = nil
    when "undeveloped"
      self.bedrooms = nil
      self.bathrooms = nil
      self.square_feet = nil
    end
  end

  def feature_catalog_type
    effective_type
  end

  def feature_catalog_scope
    :unit
  end

  def format_count(value)
    value.to_i == value ? value.to_i : value
  end
end
