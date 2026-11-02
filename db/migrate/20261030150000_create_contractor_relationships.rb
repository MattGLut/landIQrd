class CreateContractorRelationships < ActiveRecord::Migration[8.1]
  def change
    create_table :contractor_relationships do |t|
      t.references :landlord, null: false, foreign_key: { to_table: :users }
      t.references :contractor, null: false, foreign_key: { to_table: :users }
      t.integer :kind, null: false, default: 0

      t.timestamps
    end

    add_index :contractor_relationships, %i[landlord_id contractor_id], unique: true
  end
end
