# frozen_string_literal: true

# Strip + uppercase for agency-assigned internal team member IDs (TC-02-D01).
# Do not use for external_reference or display-oriented fields.
module NormalizesTeamMemberNumber
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_team_member_number
  end

  private

  def normalize_team_member_number
    return if team_member_number.blank?

    self.team_member_number = team_member_number.to_s.strip.upcase.presence
  end
end
