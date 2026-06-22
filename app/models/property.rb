class Property < ApplicationRecord
  belongs_to :landlord, class_name: "User", inverse_of: :properties
  has_many :units, dependent: :destroy
  has_many :leases, through: :units

  validates :name, presence: true

  def full_address
    [ address_line1, address_line2, city, state, postal_code ].compact_blank.join(", ")
  end
end
