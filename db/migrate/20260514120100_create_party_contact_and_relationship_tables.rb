# frozen_string_literal: true

class CreatePartyContactAndRelationshipTables < ActiveRecord::Migration[8.1]
  def change
    create_table :party_contact_methods do |t|
      t.references :party, null: false, foreign_key: true
      t.string :contact_type, null: false
      t.string :label
      t.text :value, null: false
      t.text :normalized_value
      t.boolean :is_primary, null: false, default: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :party_contact_methods, %i[party_id contact_type]

    create_table :party_relationships do |t|
      t.references :agency, null: false, foreign_key: true
      t.bigint :source_party_id, null: false
      t.bigint :target_party_id, null: false
      t.string :relationship_type, null: false
      t.string :status, null: false, default: "active"
      t.date :effective_start_date
      t.date :effective_end_date
      t.text :notes
      t.timestamps
    end

    add_index :party_relationships, :source_party_id
    add_index :party_relationships, :target_party_id
    add_index :party_relationships, %i[agency_id source_party_id relationship_type],
      name: "index_party_relationships_on_agency_source_type"

    add_foreign_key :party_relationships, :parties, column: :source_party_id
    add_foreign_key :party_relationships, :parties, column: :target_party_id
  end
end
