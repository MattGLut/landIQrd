class CreateWorkOrderEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :work_order_events do |t|
      t.references :work_order, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :action, null: false
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :work_order_events, [ :work_order_id, :created_at ]
  end
end
