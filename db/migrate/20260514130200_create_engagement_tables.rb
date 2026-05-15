# frozen_string_literal: true

class CreateEngagementTables < ActiveRecord::Migration[8.1]
  def change
    create_table :engagements do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :team_member, null: false, foreign_key: true
      t.string :relationship_type, null: false
      t.string :status, null: false, default: "draft"
      t.string :title
      t.date :start_on
      t.date :end_on
      t.date :expected_end_on
      t.date :renewal_on
      t.text :notes
      t.timestamps
    end
    add_index :engagements, %i[agency_id team_member_id]
    add_index :engagements, %i[agency_id relationship_type status]
    add_index :engagements, %i[agency_id team_member_id relationship_type]

    create_table :engagement_organization_placements do |t|
      t.references :agency, null: false, foreign_key: true
      t.references :engagement, null: false, foreign_key: true
      t.references :department, foreign_key: true
      t.references :location, foreign_key: true
      t.references :team, foreign_key: true
      t.date :effective_start_on, null: false
      t.date :effective_end_on
      t.text :notes
      t.timestamps
    end
    add_index :engagement_organization_placements, %i[engagement_id effective_start_on],
      name: "index_eop_on_engagement_and_effective_start"

    create_table :engagement_supervision_assignments do |t|
      t.bigint :agency_id, null: false
      t.bigint :engagement_id, null: false
      t.bigint :supervisor_engagement_id, null: false
      t.string :relationship_type, null: false, default: "primary_reports_to"
      t.date :effective_start_on, null: false
      t.date :effective_end_on
      t.text :notes
      t.timestamps
    end
    add_index :engagement_supervision_assignments, :agency_id
    add_index :engagement_supervision_assignments, :engagement_id
    add_index :engagement_supervision_assignments, :supervisor_engagement_id
    add_index :engagement_supervision_assignments,
      %i[engagement_id effective_start_on],
      name: "index_esa_on_engagement_and_effective_start"

    add_foreign_key :engagement_supervision_assignments, :agencies
    add_foreign_key :engagement_supervision_assignments, :engagements, column: :engagement_id
    add_foreign_key :engagement_supervision_assignments, :engagements, column: :supervisor_engagement_id
  end
end
