class CreateWalkthroughSlotsAndBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :walkthrough_slots do |t|
      t.references :job, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :capacity, default: 1, null: false

      t.timestamps
    end

    add_index :walkthrough_slots, [ :job_id, :starts_at ]

    create_table :walkthrough_bookings do |t|
      t.references :walkthrough_slot, null: false, foreign_key: true
      t.references :contractor, null: false, foreign_key: { to_table: :users }
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :walkthrough_bookings, [ :walkthrough_slot_id, :contractor_id ],
              unique: true, name: "index_walkthrough_bookings_on_slot_and_contractor"
  end
end
