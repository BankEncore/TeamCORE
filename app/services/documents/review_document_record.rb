# frozen_string_literal: true

module Documents
  # Expected failure contract for review actions (TC-08) — controllers should not rescue these as infrastructure errors.
  ReviewDocumentRecordResult = Data.define(:success?, :document_record, :error_messages) do
    def failure?
      !success?
    end
  end

  class ReviewDocumentRecord
    def self.call(document_record:, action:, reviewer:, notes: nil, rejection_reason: nil)
      new(
        document_record:,
        action: action.to_sym,
        reviewer:,
        notes:,
        rejection_reason:
      ).call
    end

    def initialize(document_record:, action:, reviewer:, notes:, rejection_reason:)
      @document_record = document_record
      @action = action
      @reviewer = reviewer
      @notes = notes
      @rejection_reason = rejection_reason
    end

    def call
      return failure([ "Reviewer required" ]) if @reviewer.blank?

      case @action
      when :verify
        apply_verify
      when :reject
        apply_reject
      when :void
        apply_void
      else
        failure([ "Invalid review action" ])
      end
    end

    private

    def apply_verify
      return failure([ "Verify is only allowed when status is submitted." ]) unless @document_record.status == "submitted"

      @document_record.assign_attributes(
        status: "verified",
        verified_by_id: @reviewer.id,
        verified_on: Date.current,
        rejection_reason: nil,
        verification_notes: normalized_notes
      )
      persist!
    end

    def apply_reject
      return failure([ "Reject is only allowed when status is submitted." ]) unless @document_record.status == "submitted"
      return failure([ "Rejection reason can't be blank." ]) if @rejection_reason.blank?

      @document_record.assign_attributes(
        status: "rejected",
        verified_by_id: @reviewer.id,
        verified_on: Date.current,
        rejection_reason: @rejection_reason.to_s.strip,
        verification_notes: normalized_notes
      )
      persist!
    end

    def apply_void
      return failure([ "Void is not allowed — record is already voided." ]) if @document_record.status == "voided"
      unless %w[submitted verified rejected].include?(@document_record.status)
        return failure([ "Void is not allowed for this status." ])
      end

      if @notes.present?
        @document_record.verification_notes = normalized_notes
      end
      # Preserve verified_by_id, verified_on, rejection_reason when leaving verified/rejected (TC-08).
      @document_record.status = "voided"

      persist!
    end

    def normalized_notes
      @notes&.to_s&.strip.presence
    end

    def failure(messages)
      Documents::ReviewDocumentRecordResult.new(success?: false, document_record: @document_record, error_messages: messages)
    end

    def persist!
      messages = nil
      DocumentRecord.transaction(requires_new: true) do
        unless @document_record.save
          messages = @document_record.errors.full_messages
          raise ActiveRecord::Rollback
        end
      end

      record = @document_record.reload
      if messages
        return Documents::ReviewDocumentRecordResult.new(success?: false, document_record: record, error_messages: messages)
      end

      Documents::ReviewDocumentRecordResult.new(success?: true, document_record: record, error_messages: [])
    end
  end
end
