# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_22_172105) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "conversation_participants", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "last_read_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["conversation_id", "user_id"], name: "index_conversation_participants_on_conversation_id_and_user_id", unique: true
    t.index ["conversation_id"], name: "index_conversation_participants_on_conversation_id"
    t.index ["user_id"], name: "index_conversation_participants_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "subject"
    t.datetime "updated_at", null: false
    t.bigint "work_order_id"
    t.index ["work_order_id"], name: "index_conversations_on_work_order_id"
  end

  create_table "lease_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.decimal "deposit_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "email", null: false
    t.date "end_date"
    t.datetime "expires_at", null: false
    t.bigint "invited_by_id", null: false
    t.bigint "lease_id"
    t.decimal "rent_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.date "start_date", null: false
    t.integer "status", default: 0, null: false
    t.string "token", null: false
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_lease_invitations_on_email"
    t.index ["invited_by_id"], name: "index_lease_invitations_on_invited_by_id"
    t.index ["lease_id"], name: "index_lease_invitations_on_lease_id"
    t.index ["token"], name: "index_lease_invitations_on_token", unique: true
    t.index ["unit_id"], name: "index_lease_invitations_on_unit_id"
  end

  create_table "leases", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "deposit_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.date "end_date"
    t.decimal "rent_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.date "start_date", null: false
    t.integer "status", default: 0, null: false
    t.bigint "tenant_id", null: false
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tenant_id"], name: "index_leases_on_tenant_id"
    t.index ["unit_id"], name: "index_leases_on_unit_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "author_id", null: false
    t.text "body"
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_messages_on_author_id"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.datetime "created_at", null: false
    t.bigint "landlord_id", null: false
    t.string "name", null: false
    t.string "postal_code"
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["landlord_id"], name: "index_properties_on_landlord_id"
  end

  create_table "units", force: :cascade do |t|
    t.decimal "bathrooms", precision: 3, scale: 1
    t.integer "bedrooms"
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.bigint "property_id", null: false
    t.integer "square_feet"
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_units_on_property_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "company_name"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "preferred_name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "work_order_assignments", force: :cascade do |t|
    t.bigint "contractor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "scheduled_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "work_order_id", null: false
    t.index ["contractor_id"], name: "index_work_order_assignments_on_contractor_id"
    t.index ["work_order_id", "contractor_id"], name: "idx_on_work_order_id_contractor_id_d208563876", unique: true
    t.index ["work_order_id"], name: "index_work_order_assignments_on_work_order_id"
  end

  create_table "work_order_events", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "work_order_id", null: false
    t.index ["user_id"], name: "index_work_order_events_on_user_id"
    t.index ["work_order_id", "created_at"], name: "index_work_order_events_on_work_order_id_and_created_at"
    t.index ["work_order_id"], name: "index_work_order_events_on_work_order_id"
  end

  create_table "work_orders", force: :cascade do |t|
    t.string "category", default: "general", null: false
    t.datetime "closed_at"
    t.bigint "closed_by_id"
    t.text "closure_reason"
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.text "description"
    t.bigint "lease_id"
    t.integer "priority", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.bigint "unit_id", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_work_orders_on_category"
    t.index ["closed_by_id"], name: "index_work_orders_on_closed_by_id"
    t.index ["created_by_id"], name: "index_work_orders_on_created_by_id"
    t.index ["lease_id"], name: "index_work_orders_on_lease_id"
    t.index ["priority"], name: "index_work_orders_on_priority"
    t.index ["status"], name: "index_work_orders_on_status"
    t.index ["unit_id"], name: "index_work_orders_on_unit_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "conversation_participants", "conversations"
  add_foreign_key "conversation_participants", "users"
  add_foreign_key "conversations", "work_orders"
  add_foreign_key "lease_invitations", "leases"
  add_foreign_key "lease_invitations", "units"
  add_foreign_key "lease_invitations", "users", column: "invited_by_id"
  add_foreign_key "leases", "units"
  add_foreign_key "leases", "users", column: "tenant_id"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users", column: "author_id"
  add_foreign_key "properties", "users", column: "landlord_id"
  add_foreign_key "units", "properties"
  add_foreign_key "work_order_assignments", "users", column: "contractor_id"
  add_foreign_key "work_order_assignments", "work_orders"
  add_foreign_key "work_order_events", "users"
  add_foreign_key "work_order_events", "work_orders"
  add_foreign_key "work_orders", "leases"
  add_foreign_key "work_orders", "units"
  add_foreign_key "work_orders", "users", column: "closed_by_id"
  add_foreign_key "work_orders", "users", column: "created_by_id"
end
