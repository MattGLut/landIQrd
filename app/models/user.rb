class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, { tenant: 0, landlord: 1, contractor: 2, admin: 3 }

  has_many :properties, foreign_key: :landlord_id, dependent: :destroy, inverse_of: :landlord
  has_many :leases, foreign_key: :tenant_id, dependent: :destroy, inverse_of: :tenant
  has_many :created_work_orders, class_name: "WorkOrder", foreign_key: :created_by_id,
                                 dependent: :destroy, inverse_of: :created_by
  has_many :closed_work_orders, class_name: "WorkOrder", foreign_key: :closed_by_id,
                                dependent: :nullify, inverse_of: :closed_by
  has_many :work_order_assignments, foreign_key: :contractor_id, dependent: :destroy, inverse_of: :contractor
  has_many :assigned_work_orders, through: :work_order_assignments, source: :work_order
  has_many :conversation_participants, dependent: :destroy
  has_many :conversations, through: :conversation_participants
  has_many :messages, foreign_key: :author_id, dependent: :destroy, inverse_of: :author
  has_many :sent_lease_invitations, class_name: "LeaseInvitation", foreign_key: :invited_by_id,
                                    dependent: :destroy, inverse_of: :invited_by

  has_one_attached :avatar

  validates :role, presence: true
  validates :first_name, :last_name, presence: true
  validates :preferred_name, length: { maximum: 100 }, allow_blank: true
  validate :avatar_content_type
  validate :avatar_size

  def full_name
    [ first_name, last_name ].compact_blank.join(" ").presence || email
  end

  def display_name
    preferred_name.presence || company_name.presence || full_name
  end

  def greeting_name
    preferred_name.presence || first_name
  end

  def initials
    source = preferred_name.presence || full_name
    parts = source.split(/\s+/)
    if parts.length >= 2
      "#{parts.first[0]}#{parts.last[0]}".upcase
    else
      source.first(2).upcase
    end
  end

  private

  def avatar_content_type
    return unless avatar.attached?

    unless avatar.content_type.in?(%w[image/png image/jpeg image/webp])
      errors.add(:avatar, "must be a PNG, JPEG, or WebP image")
    end
  end

  def avatar_size
    return unless avatar.attached?

    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, "must be smaller than 5 MB")
    end
  end
end
