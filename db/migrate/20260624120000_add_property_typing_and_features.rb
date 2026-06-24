class AddPropertyTypingAndFeatures < ActiveRecord::Migration[8.0]
  def change
    change_table :properties, bulk: true do |t|
      t.integer :property_type, null: false, default: 0
      t.jsonb :features, null: false, default: {}
    end

    change_table :units, bulk: true do |t|
      t.integer :unit_type
      t.decimal :acreage, precision: 10, scale: 2
      t.jsonb :features, null: false, default: {}
    end
  end
end
