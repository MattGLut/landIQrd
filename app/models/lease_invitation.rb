class LeaseInvitation < ApplicationRecord
  belongs_to :unit
  belongs_to :invited_by, class_name: "User"
  belongs_to :lease, optional: true

  enum :status, { pending: 0, accepted: 1, expired: 2, cancelled: 3 }, prefix: true

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :start_date, presence: true
  validates :rent_amount, :deposit_amount, numericality: { greater_than_or_equal_to: 0 }
  validate :end_after_start

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  scope :usable, -> { status_pending.where("expires_at > ?", Time.current) }

  def expired?
    expires_at.past? || status_expired?
  end

  def accept!(user)
    raise "Invitation is no longer valid" unless usable?

    transaction do
      lease = unit.leases.create!(
        tenant: user,
        start_date: start_date,
        end_date: end_date,
        rent_amount: rent_amount,
        deposit_amount: deposit_amount,
        status: :draft
      )
      update!(status: :accepted, accepted_at: Time.current, lease: lease)
      lease
    end
  end

  def usable?
    status_pending? && expires_at.future?
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= 14.days.from_now
  end

  def end_after_start
    return if end_date.blank? || start_date.blank?

    errors.add(:end_date, "must be after the start date") if end_date < start_date
  end
end
