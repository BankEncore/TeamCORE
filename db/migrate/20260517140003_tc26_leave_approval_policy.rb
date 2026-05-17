# frozen_string_literal: true

class Tc26LeaveApprovalPolicy < ActiveRecord::Migration[8.1]
  def change
    add_column :leave_types, :approval_policy, :string, null: false, default: "manual"

    change_column_null :leave_request_approval_events, :actor_id, true
  end
end
