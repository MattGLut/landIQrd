class CreateWorkOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :work_orders do |t|
      t.references :unit, null: false, foreign_key: true
      t.references :lease, null: true, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.integer :priority, null: false, default: 1
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :work_orders, :status
    add_index :work_orders, :priority
  end
end
