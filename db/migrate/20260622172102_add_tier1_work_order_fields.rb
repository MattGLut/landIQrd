class AddTier1WorkOrderFields < ActiveRecord::Migration[8.1]
  def change
    add_column :work_orders, :category, :string, default: "general", null: false
    add_column :work_orders, :closure_reason, :text
    add_reference :work_orders, :closed_by, foreign_key: { to_table: :users }
    add_column :work_orders, :closed_at, :datetime
    add_index :work_orders, :category
  end
end
