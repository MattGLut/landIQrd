class CreateLeaseInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :lease_invitations do |t|
      t.references :unit, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :email, null: false
      t.string :token, null: false
      t.integer :status, null: false, default: 0
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.date :start_date, null: false
      t.date :end_date
      t.decimal :rent_amount, precision: 10, scale: 2, default: "0.0", null: false
      t.decimal :deposit_amount, precision: 10, scale: 2, default: "0.0", null: false
      t.references :lease, foreign_key: true

      t.timestamps
    end

    add_index :lease_invitations, :token, unique: true
    add_index :lease_invitations, :email
  end
end
