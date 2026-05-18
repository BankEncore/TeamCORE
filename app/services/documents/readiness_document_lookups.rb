# frozen_string_literal: true

module Documents
  # Shared DocumentType / DocumentRecord lookups for ReadinessResult UIs (Team360, guided onboarding).
  module ReadinessDocumentLookups
    module_function

    # @return [Array(Hash<Integer, DocumentType>, Hash<Integer, DocumentRecord>)]
    def indexes_from(readiness_result)
      return [ {}, {} ] unless readiness_result

      type_ids =
        (
          readiness_result.requirements.map(&:document_type_id) +
          readiness_result.alerts.map(&:document_type_id)
        ).uniq
      doc_types_by_id = DocumentType.where(id: type_ids).index_by(&:id)

      rec_ids = readiness_result.requirements.filter_map(&:document_record_id).uniq
      records_by_id =
        if rec_ids.empty?
          {}
        else
          DocumentRecord.where(id: rec_ids).includes(:verified_by).index_by(&:id)
        end

      [ doc_types_by_id, records_by_id ]
    end
  end
end
