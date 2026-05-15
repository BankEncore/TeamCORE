# frozen_string_literal: true

# Optional additive indexes for agency-scoped reporting/filtering queries (TC-01).
class AddOrganizationFoundationFilteringIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :departments, %i[agency_id status]
    add_index :locations, %i[agency_id status]
    add_index :locations, %i[agency_id location_type]
    add_index :teams, %i[agency_id status]
    add_index :teams, %i[agency_id department_id]
    add_index :teams, %i[agency_id location_id]
  end
end
