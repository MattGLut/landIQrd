class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units do |t|
      t.references :property, null: false, foreign_key: true
      t.string :label, null: false
      t.integer :bedrooms
      t.decimal :bathrooms, precision: 3, scale: 1
      t.integer :square_feet

      t.timestamps
    end
  end
end
