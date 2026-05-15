# frozen_string_literal: true

module Subcontractors
  class PromoteRelatedParty
    Result = Struct.new(:success, :engagement, :flash, :flash_key, keyword_init: true) do
      def success?
        success
      end
    end

    def self.call(party_relationship:, agency:)
      new(party_relationship:, agency:).call
    end

    def initialize(party_relationship:, agency:)
      @party_relationship = party_relationship
      @agency = agency
    end

    attr_reader :party_relationship, :agency

    def call
      rel = party_relationship

      unless rel.subcontractor?
        return failure(:alert, "Not a subcontractor relationship.")
      end
      unless rel.agency_id == agency.id
        return failure(:alert, "Relationship belongs to another agency.")
      end
      unless rel.active? && rel.currently_effective_on?(Date.current)
        return failure(:alert,
          "Promotion requires an active subcontractor relationship that is currently effective.")
      end

      target = rel.target_party
      unless target&.identity_complete?
        return failure(:alert, "Target party identity must be complete before promotion.")
      end
      unless rel.source_party.subcontractor_source_contractor_capable_for_agency?(agency)
        return failure(:alert, "Source is no longer eligible as a subcontractor relationship source.")
      end

      result = nil
      ApplicationRecord.transaction do
        tm = TeamMember.find_or_initialize_by(agency_id: agency.id, party_id: target.id)
        tm.status = "active" if tm.new_record?
        tm.save!

        subs = Engagement.where(
          agency_id: agency.id,
          team_member_id: tm.id,
          relationship_type: "subcontractor"
        )
        if (active_one = subs.find_by(status: "active"))
          result = ok(
            :notice,
            "Subcontractor already has an active subcontractor engagement.",
            active_one
          )
        elsif (reuse = subs.where(status: %w[draft pending]).order(:id).first)
          result =
            ok(:notice, "Subcontractor engagement already exists for this party (reusing draft or pending).", reuse)
        else
          eng = Engagement.new(
            agency_id: agency.id,
            team_member_id: tm.id,
            relationship_type: "subcontractor",
            status: "draft"
          )
          raise ActiveRecord::RecordInvalid, eng unless eng.save

          result = ok(:notice, "Subcontractor engagement created.", eng)
        end
      end
      result
    rescue ActiveRecord::RecordInvalid => e
      failure(:alert, e.record.errors.full_messages.join("; "))
    end

    private

    def ok(key, message, engagement)
      Result.new(success: true, engagement:, flash: message, flash_key: key)
    end

    def failure(key, message)
      Result.new(success: false, engagement: nil, flash: message, flash_key: key)
    end
  end
end
