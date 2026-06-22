class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :work_order, null: true, foreign_key: true
      t.string :subject

      t.timestamps
    end
  end
end
