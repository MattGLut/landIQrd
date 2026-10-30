class AddStatusToContractorRelationships < ActiveRecord::Migration[8.1]
  def change
    add_column :contractor_relationships, :status, :integer, null: false, default: 0
    add_index :contractor_relationships, :status
  end
end