class CreateLeases < ActiveRecord::Migration[8.1]
  def change
    create_table :leases do |t|
      t.references :unit, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: { to_table: :users }
      t.date :start_date, null: false
      t.date :end_date
      t.decimal :rent_amount, precision: 10, scale: 2, null: false, default: "0.0"
      t.decimal :deposit_amount, precision: 10, scale: 2, null: false, default: "0.0"
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
