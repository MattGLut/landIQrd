class CreateWorkOrderAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :work_order_assignments do |t|
      t.references :work_order, null: false, foreign_key: true
      t.references :contractor, null: false, foreign_key: { to_table: :users }
      t.datetime :scheduled_at
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :work_order_assignments, %i[work_order_id contractor_id], unique: true
  end
end
