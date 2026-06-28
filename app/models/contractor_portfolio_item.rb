class ContractorPortfolioItem < ApplicationRecord
  include WorkOrderCategory

  belongs_to :contractor, class_name: "User", inverse_of: :contractor_portfolio_items

  has_many_attached :photos

  validates :title, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES.keys.map(&:to_s) }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :contractor_must_be_contractor
  validate :photos_attached_on_create, on: :create
  validate :photos_content_type
  validate :photos_size

  scope :ordered, -> { order(:position, :created_at) }
  scope :for_category, ->(category) { category.present? ? where(category: category) : all }

  def self.next_position_for(contractor)
    where(contractor: contractor).maximum(:position).to_i + 1
  end

  private

  def contractor_must_be_contractor
    return if contractor&.contractor?

    errors.add(:contractor, "must be a contractor")
  end

  def photos_attached_on_create
    return if photos.attached?

    errors.add(:photos, "must include at least one image")
  end

  def photos_content_type
    return unless photos.attached?

    photos.each do |photo|
      next if photo.content_type.in?(%w[image/png image/jpeg image/webp image/gif])

      errors.add(:photos, "must be PNG, JPEG, WebP, or GIF images")
      break
    end
  end

  def photos_size
    return unless photos.attached?

    photos.each do |photo|
      next if photo.byte_size <= 5.megabytes

      errors.add(:photos, "must be smaller than 5 MB each")
      break
    end
  end
end
