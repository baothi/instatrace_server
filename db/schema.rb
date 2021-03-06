# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20121018051754) do

  create_table "active_admin_comments", :force => true do |t|
    t.integer  "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "agents", :force => true do |t|
    t.string   "name"
    t.string   "address"
    t.string   "city"
    t.string   "phone"
    t.string   "ext"
    t.string   "zip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "created_by"
    t.string   "updated_by"
  end

  create_table "companies", :force => true do |t|
    t.string   "name"
    t.string   "address"
    t.string   "city"
    t.string   "phone"
    t.string   "ext"
    t.string   "zip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "company_type_id"
    t.string   "created_by"
    t.string   "updated_by"
  end

  create_table "company_relations", :force => true do |t|
    t.integer  "company_id", :null => false
    t.integer  "agent_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "damages", :force => true do |t|
    t.integer  "milestone_id"
    t.string   "photo"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "locations", :force => true do |t|
    t.integer  "driver_id"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "locations_shipments", :id => false, :force => true do |t|
    t.integer "location_id"
    t.integer "shipment_id"
  end

  add_index "locations_shipments", ["location_id"], :name => "index_locations_shipments_on_location_id"

  create_table "milestone_documents", :force => true do |t|
    t.integer  "milestone_id", :null => false
    t.string   "name",         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "doc_type"
  end

  create_table "milestones", :force => true do |t|
    t.integer  "driver_id"
    t.integer  "shipment_id"
    t.string   "action"
    t.boolean  "damaged"
    t.text     "damage_desc"
    t.boolean  "completed"
    t.boolean  "public"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "location"
    t.float    "latitude",    :limit => 10,                               :default => 0.0
    t.float    "longitude",   :limit => 10,                               :default => 0.0
    t.decimal  "timezone",                  :precision => 2, :scale => 1
    t.string   "address"
  end

  add_index "milestones", ["action"], :name => "index_milestones_on_action"
  add_index "milestones", ["driver_id"], :name => "index_milestones_on_driver_id"
  add_index "milestones", ["shipment_id"], :name => "index_milestones_on_shipment_id"

  create_table "notifications", :force => true do |t|
    t.integer  "user_id"
    t.string   "event"
    t.string   "shipment_id"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions", :force => true do |t|
    t.string   "action"
    t.string   "subject_class"
    t.text     "conditions"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions_roles", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "permission_id"
  end

  create_table "pieces", :force => true do |t|
    t.integer  "pieces"
    t.float    "weight"
    t.float    "length"
    t.float    "height"
    t.integer  "shipment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "shipments", :force => true do |t|
    t.string   "shipment_id"
    t.integer  "pieces_total"
    t.float    "weight"
    t.string   "origin"
    t.string   "shipper"
    t.datetime "ship_date"
    t.string   "destination"
    t.string   "consignee"
    t.datetime "delivery_date"
    t.string   "service_level"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "hawb"
    t.string   "mawb"
    t.string   "carrier_scac_code",                 :limit => 15
    t.string   "receiver_scac_code",                :limit => 15
    t.string   "origin_address1"
    t.string   "origin_address2"
    t.string   "origin_city"
    t.string   "origin_state"
    t.string   "origin_zip_postal_code"
    t.string   "origin_country"
    t.string   "dest_address1"
    t.string   "dest_address2"
    t.string   "dest_city"
    t.string   "dest_state"
    t.string   "dest_zip_postal_code"
    t.string   "dest_country"
    t.float    "length"
    t.float    "height"
    t.string   "service_level_code",                :limit => 2
    t.string   "pick_up_and_delivery_instructions", :limit => 2
    t.string   "shipment_types",                    :limit => 2
  end

  add_index "shipments", ["hawb"], :name => "index_shipments_on_hawb"

  create_table "signatures", :force => true do |t|
    t.integer  "milestone_id"
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "signature"
  end

  create_table "user_relations", :force => true do |t|
    t.integer  "user_id",    :null => false
    t.integer  "owner_id",   :null => false
    t.string   "owner_type", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "login"
    t.integer  "role_id"
    t.string   "address"
    t.string   "language"
    t.string   "api_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "phone"
    t.string   "name"
    t.integer  "company_id"
    t.string   "last_name"
    t.string   "first_name"
    t.string   "ext"
    t.string   "activation_code"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
