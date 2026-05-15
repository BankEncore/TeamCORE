# frozen_string_literal: true

class CreatePartyIdentityTables < ActiveRecord::Migration[8.1]
  def change
    create_table :parties do |t|
      t.references :agency, null: false, foreign_key: true
      t.string :party_type, null: false
      t.string :display_name
      t.string :status, null: false, default: "active"
      t.string :external_reference
      t.text :notes
      t.timestamps
    end
    add_index :parties, %i[agency_id party_type]
    add_index :parties, %i[agency_id status]

    create_table :person_profiles do |t|
      t.references :party, null: false, foreign_key: true, index: { unique: true }
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :preferred_name
      t.string :suffix
      t.timestamps
    end

    create_table :organization_profiles do |t|
      t.references :party, null: false, foreign_key: true, index: { unique: true }
      t.string :legal_name
      t.string :trade_name
      t.string :organization_kind, null: false
      t.timestamps
    end
    add_index :organization_profiles, :organization_kind

    create_table :team_members do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :party, null: false, foreign_key: true
      t.string :team_member_number
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :team_members, %i[agency_id party_id], unique: true,
      name: "index_team_members_on_agency_and_party_unique"
    add_index :team_members, %i[agency_id team_member_number], unique: true,
      name: "index_team_members_on_agency_and_number_unique"
  end
end
