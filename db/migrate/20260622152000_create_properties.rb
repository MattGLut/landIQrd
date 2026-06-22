class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties do |t|
      t.references :landlord, null: false, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :state
      t.string :postal_code

      t.timestamps
    end
  end
end
