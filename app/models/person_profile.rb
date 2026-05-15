# frozen_string_literal: true

class PersonProfile < ApplicationRecord
  belongs_to :party, inverse_of: :person_profile

  validates :party, presence: true
  validate :party_must_be_person

  after_save :maybe_fill_party_display_name

  def self.compose_display_candidate(profile)
    p = profile
    if p.preferred_name.present? && p.last_name.present?
      "#{p.preferred_name} #{p.last_name}".strip
    elsif p.first_name.present? || p.last_name.present?
      [ p.first_name, p.last_name ].compact.join(" ").strip.presence
    end
  end

  private

  def party_must_be_person
    return if party.blank?

    errors.add(:party, :invalid) unless party.person?
  end

  def maybe_fill_party_display_name
    return if party.blank? || party.display_name.present?

    cand = PersonProfile.compose_display_candidate(self)
    return if cand.blank?

    party.update_columns(display_name: cand, updated_at: Time.current)
  end
end
