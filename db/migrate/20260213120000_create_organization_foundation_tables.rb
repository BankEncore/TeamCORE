# frozen_string_literal: true

class CreateOrganizationFoundationTables < ActiveRecord::Migration[8.1]
  def change
    create_table :agencies do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :agencies, :code, unique: true

    create_table :departments do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :parent_department, foreign_key: { to_table: :departments }, null: true
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :departments, %i[agency_id code], unique: true

    create_table :locations do |t|
      t.references :agency, null: false, foreign_key: true
      t.string :name, null: false
      t.string :code, null: false
      t.string :location_type, null: false
      t.string :timezone
      t.text :description
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :locations, %i[agency_id code], unique: true

    create_table :teams do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :department, foreign_key: true, null: true
      t.references :location, foreign_key: true, null: true
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :teams, %i[agency_id code], unique: true
  end
end
