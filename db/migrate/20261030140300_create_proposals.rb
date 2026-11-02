class CreateProposals < ActiveRecord::Migration[8.1]
  def change
    create_table :proposals do |t|
      t.references :job, null: false, foreign_key: true
      t.references :contractor, null: false, foreign_key: { to_table: :users }
      t.bigint :amount_cents, null: false
      t.text :scope, null: false
      t.text :exclusions
      t.date :earliest_start
      t.integer :estimated_duration_days
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :proposals, [ :job_id, :contractor_id ], unique: true
    add_index :proposals, :status

    add_column :work_orders, :price_cents, :bigint
    add_reference :work_orders, :proposal, foreign_key: true
  end
end
