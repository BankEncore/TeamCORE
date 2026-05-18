# frozen_string_literal: true

module Documents
  PostReviewDocumentRecordPatchResult = Data.define(:success?, :document_record, :error_messages) do
    def failure?
      !success?
    end
  end

  # Applies metadata edits after a record leaves the submitted queue (verified / rejected / voided).
  # TC-08 / TC-29: actor is reserved for future verifier-only enforcement.
  class PostReviewDocumentRecordPatch
    ALLOWED_ATTRIBUTE_KEYS = %i[
      display_name filename storage_key content_type byte_size
      issued_on expires_on
    ].freeze

    ALLOWED_KEY_STRINGS = ALLOWED_ATTRIBUTE_KEYS.map(&:to_s).freeze

    def self.call(document_record:, attributes:, actor: nil)
      new(document_record: document_record, attributes: attributes).call
    end

    def initialize(document_record:, attributes:)
      @document_record = document_record
      @attributes = attributes
    end

    def call
      raw =
        case @attributes
        when ActionController::Parameters
          @attributes.to_unsafe_h
        when Hash
          @attributes.stringify_keys
        else
          @attributes.to_h.stringify_keys
        end

      keys = raw.keys.map(&:to_s)
      unknown = keys - ALLOWED_KEY_STRINGS
      if unknown.any?
        return failure([ "Disallowed attributes: #{unknown.sort.join(', ')}" ])
      end

      slice = raw.slice(*ALLOWED_KEY_STRINGS)
      @document_record.assign_attributes(slice)

      if @document_record.save
        PostReviewDocumentRecordPatchResult.new(success?: true, document_record: @document_record, error_messages: [])
      else
        PostReviewDocumentRecordPatchResult.new(
          success?: false,
          document_record: @document_record,
          error_messages: @document_record.errors.full_messages
        )
      end
    end

    private

    def failure(messages)
      PostReviewDocumentRecordPatchResult.new(success?: false, document_record: @document_record, error_messages: messages)
    end
  end
end
