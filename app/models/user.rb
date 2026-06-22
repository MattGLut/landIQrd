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
  has_many :work_order_assignments, foreign_key: :contractor_id, dependent: :destroy, inverse_of: :contractor
  has_many :assigned_work_orders, through: :work_order_assignments, source: :work_order
  has_many :conversation_participants, dependent: :destroy
  has_many :conversations, through: :conversation_participants
  has_many :messages, foreign_key: :author_id, dependent: :destroy, inverse_of: :author

  validates :role, presence: true
  validates :first_name, :last_name, presence: true

  def full_name
    [ first_name, last_name ].compact_blank.join(" ").presence || email
  end

  def display_name
    company_name.presence || full_name
  end
end
