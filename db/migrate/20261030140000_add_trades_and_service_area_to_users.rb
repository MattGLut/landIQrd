class AddTradesAndServiceAreaToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :trades, :string, array: true, default: [], null: false
    add_column :users, :service_city, :string
    add_column :users, :service_state, :string
    add_column :users, :service_radius_miles, :integer, default: 30, null: false
    add_column :users, :notify_matching_jobs, :boolean, default: true, null: false

    add_index :users, :trades, using: :gin
  end
end
