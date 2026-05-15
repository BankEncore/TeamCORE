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

ActiveRecord::Schema[8.1].define(version: 2026_05_14_120100) do
  create_table "agencies", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_agencies_on_code", unique: true
  end

  create_table "departments", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "parent_department_id"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id", "code"], name: "index_departments_on_agency_id_and_code", unique: true
    t.index ["agency_id", "status"], name: "index_departments_on_agency_id_and_status"
    t.index ["agency_id"], name: "index_departments_on_agency_id"
    t.index ["parent_department_id"], name: "index_departments_on_parent_department_id"
  end

  create_table "locations", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "location_type", null: false
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.string "timezone"
    t.datetime "updated_at", null: false
    t.index ["agency_id", "code"], name: "index_locations_on_agency_id_and_code", unique: true
    t.index ["agency_id", "location_type"], name: "index_locations_on_agency_id_and_location_type"
    t.index ["agency_id", "status"], name: "index_locations_on_agency_id_and_status"
    t.index ["agency_id"], name: "index_locations_on_agency_id"
  end

  create_table "organization_profiles", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "legal_name"
    t.string "organization_kind", null: false
    t.bigint "party_id", null: false
    t.string "trade_name"
    t.datetime "updated_at", null: false
    t.index ["organization_kind"], name: "index_organization_profiles_on_organization_kind"
    t.index ["party_id"], name: "index_organization_profiles_on_party_id", unique: true
  end

  create_table "parties", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "external_reference"
    t.text "notes"
    t.string "party_type", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id", "party_type"], name: "index_parties_on_agency_id_and_party_type"
    t.index ["agency_id", "status"], name: "index_parties_on_agency_id_and_status"
    t.index ["agency_id"], name: "index_parties_on_agency_id"
  end

  create_table "party_contact_methods", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.string "contact_type", null: false
    t.datetime "created_at", null: false
    t.boolean "is_primary", default: false, null: false
    t.string "label"
    t.text "normalized_value"
    t.bigint "party_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.text "value", null: false
    t.index ["party_id", "contact_type"], name: "index_party_contact_methods_on_party_id_and_contact_type"
    t.index ["party_id"], name: "index_party_contact_methods_on_party_id"
  end

  create_table "party_relationships", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "created_at", null: false
    t.date "effective_end_date"
    t.date "effective_start_date"
    t.text "notes"
    t.string "relationship_type", null: false
    t.bigint "source_party_id", null: false
    t.string "status", default: "active", null: false
    t.bigint "target_party_id", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id", "source_party_id", "relationship_type"], name: "index_party_relationships_on_agency_source_type"
    t.index ["agency_id"], name: "index_party_relationships_on_agency_id"
    t.index ["source_party_id"], name: "index_party_relationships_on_source_party_id"
    t.index ["target_party_id"], name: "index_party_relationships_on_target_party_id"
  end

  create_table "person_profiles", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "middle_name"
    t.bigint "party_id", null: false
    t.string "preferred_name"
    t.string "suffix"
    t.datetime "updated_at", null: false
    t.index ["party_id"], name: "index_person_profiles_on_party_id", unique: true
  end

  create_table "team_members", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.datetime "created_at", null: false
    t.bigint "party_id", null: false
    t.string "status", default: "active", null: false
    t.string "team_member_number"
    t.datetime "updated_at", null: false
    t.index ["agency_id", "party_id"], name: "index_team_members_on_agency_and_party_unique", unique: true
    t.index ["agency_id", "team_member_number"], name: "index_team_members_on_agency_and_number_unique", unique: true
    t.index ["agency_id"], name: "index_team_members_on_agency_id"
    t.index ["party_id"], name: "index_team_members_on_party_id"
  end

  create_table "teams", charset: "utf8mb4", collation: "utf8mb4_uca1400_ai_ci", force: :cascade do |t|
    t.bigint "agency_id", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.bigint "department_id"
    t.text "description"
    t.bigint "location_id"
    t.string "name", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id", "code"], name: "index_teams_on_agency_id_and_code", unique: true
    t.index ["agency_id", "department_id"], name: "index_teams_on_agency_id_and_department_id"
    t.index ["agency_id", "location_id"], name: "index_teams_on_agency_id_and_location_id"
    t.index ["agency_id", "status"], name: "index_teams_on_agency_id_and_status"
    t.index ["agency_id"], name: "index_teams_on_agency_id"
    t.index ["department_id"], name: "index_teams_on_department_id"
    t.index ["location_id"], name: "index_teams_on_location_id"
  end

  add_foreign_key "departments", "agencies"
  add_foreign_key "departments", "departments", column: "parent_department_id"
  add_foreign_key "locations", "agencies"
  add_foreign_key "organization_profiles", "parties"
  add_foreign_key "parties", "agencies"
  add_foreign_key "party_contact_methods", "parties"
  add_foreign_key "party_relationships", "agencies"
  add_foreign_key "party_relationships", "parties", column: "source_party_id"
  add_foreign_key "party_relationships", "parties", column: "target_party_id"
  add_foreign_key "person_profiles", "parties"
  add_foreign_key "team_members", "agencies"
  add_foreign_key "team_members", "parties"
  add_foreign_key "teams", "agencies"
  add_foreign_key "teams", "departments"
  add_foreign_key "teams", "locations"
end
