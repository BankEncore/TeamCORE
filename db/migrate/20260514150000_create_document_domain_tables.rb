# frozen_string_literal: true

class CreateDocumentDomainTables < ActiveRecord::Migration[8.1]
  def change
    create_table :document_types do |t|
      t.references :agency, null: false, foreign_key: true
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      t.string :category, null: false
      t.boolean :requires_expiration_date, default: false, null: false
      t.integer :default_expiring_soon_days
      t.boolean :verification_required, default: false, null: false
      t.string :status, default: "active", null: false

      t.timestamps
    end

    add_index :document_types, %i[agency_id code], unique: true
    add_index :document_types, %i[agency_id category]
    add_index :document_types, %i[agency_id status]

    create_table :document_requirements do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :document_type, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.string :requirement_scope, null: false
      t.string :relationship_type, default: "any", null: false
      t.boolean :required, default: true, null: false
      t.boolean :verification_required, default: false, null: false
      t.boolean :expiration_required, default: false, null: false
      t.integer :expiring_soon_days
      t.string :status, default: "active", null: false

      t.timestamps
    end

    add_index :document_requirements, %i[agency_id document_type_id requirement_scope relationship_type],
      unique: true,
      name: "idx_document_requirements_agency_type_scope_rel"
    add_index :document_requirements, %i[agency_id relationship_type]
    add_index :document_requirements, %i[agency_id requirement_scope]
    add_index :document_requirements, %i[agency_id status]

    create_table :document_records do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :document_type, null: false, foreign_key: true
      t.references :team_member, foreign_key: true
      t.references :engagement, foreign_key: true
      t.references :party, foreign_key: true
      t.string :storage_key
      t.string :filename
      t.string :content_type
      t.bigint :byte_size
      t.string :display_name
      t.string :status, default: "submitted", null: false
      t.date :submitted_on
      t.date :issued_on
      t.date :expires_on
      t.references :verified_by, foreign_key: { to_table: :users }
      t.date :verified_on
      t.text :verification_notes
      t.text :rejection_reason

      t.timestamps
    end

    add_index :document_records, %i[agency_id document_type_id]
    add_index :document_records, %i[agency_id team_member_id]
    add_index :document_records, %i[agency_id engagement_id]
    add_index :document_records, %i[agency_id status]
    add_index :document_records, %i[agency_id expires_on]
  end
end
