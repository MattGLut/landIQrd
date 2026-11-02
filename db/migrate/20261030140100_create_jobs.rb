class CreateJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :jobs do |t|
      t.references :property, null: false, foreign_key: true
      t.references :unit, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :work_order, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :trades, array: true, default: [], null: false
      t.date :proposal_deadline
      t.integer :status, default: 0, null: false
      t.boolean :walkthrough_required, default: false, null: false
      t.string :timezone, default: "Eastern Time (US & Canada)", null: false
      t.integer :slot_capacity, default: 1, null: false
      t.datetime :published_at

      t.timestamps
    end

    add_index :jobs, :status
    add_index :jobs, :trades, using: :gin
  end
end
