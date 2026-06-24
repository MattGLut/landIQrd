class Property < ApplicationRecord
  include HasTypedFeatures

  belongs_to :landlord, class_name: "User", inverse_of: :properties
  has_many :units, dependent: :destroy
  has_many :leases, through: :units

  enum :property_type, { residential: 0, commercial: 1, undeveloped: 2 }

  validates :name, presence: true

  def full_address
    [ address_line1, address_line2, city, state, postal_code ].compact_blank.join(", ")
  end

  def units_with_type_overrides?
    units.where.not(unit_type: nil).exists?
  end

  private

  def feature_catalog_type
    property_type
  end

  def feature_catalog_scope
    :property
  end
end
