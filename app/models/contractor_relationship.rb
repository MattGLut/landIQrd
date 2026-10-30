class ContractorRelationship < ApplicationRecord
  belongs_to :landlord, class_name: "User", inverse_of: :contractor_relationships
  belongs_to :contractor, class_name: "User", inverse_of: :landlord_relationships

  enum :kind, { personal: 0, business: 1 }, prefix: true
  enum :status, { pending: 0, accepted: 1, declined: 2 }, prefix: true

  validates :kind, :status, presence: true
  validates :contractor_id, uniqueness: { scope: :landlord_id, message: "is already saved as a contact" }
  validate :landlord_must_be_landlord
  validate :contractor_must_be_contractor

  def label
    "#{kind.titleize} contact"
  end

  def contractor_option_label
    "#{contractor.display_name} · #{label}"
  end

  def status_label
    {
      "pending" => "Awaiting acceptance",
      "accepted" => "Accepted",
      "declined" => "Declined"
    }.fetch(status)
  end

  def status_color
    {
      "pending" => :yellow,
      "accepted" => :green,
      "declined" => :red
    }.fetch(status, :gray)
  end

  private

  def landlord_must_be_landlord
    return if landlord.nil?

    errors.add(:landlord, "must be a landlord") unless landlord.landlord?
  end

  def contractor_must_be_contractor
    return if contractor.nil?

    errors.add(:contractor, "must be a contractor") unless contractor.contractor?
  end
end
