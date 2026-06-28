class AddContractorPortfolioFeatures < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :website_url, :string

    create_table :contractor_portfolio_items do |t|
      t.references :contractor, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :category, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :contractor_portfolio_items, %i[contractor_id category]
    add_index :contractor_portfolio_items, %i[contractor_id position]
  end
end
