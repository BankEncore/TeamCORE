# frozen_string_literal: true

module Documents
  class AlertMessageBuilder
    def self.build(
      outcome:,
      requirement:,
      as_of_date:,
      rejection_reason: nil,
      expires_on: nil,
      days_until_expiration: nil
    )
      rq_name = requirement.name.presence || "Requirement ##{requirement.id}"
      dt = requirement.document_type
      type_label = "#{dt.name} (#{dt.code})"

      case outcome
      when "missing"
        "#{rq_name} (#{type_label}) is missing: no usable document record on file."
      when "expired"
        "#{rq_name} (#{type_label}) expired on #{expires_on}. As of #{as_of_date}, that is #{(as_of_date - expires_on).to_i} days past expiration."
      when "expiring_soon"
        "#{rq_name} (#{type_label}) expires on #{expires_on} (#{days_until_expiration} day#{'s' if days_until_expiration.to_i.abs != 1})."
      when "rejected"
        suffix = rejection_reason.present? ? " Reason: #{rejection_reason}" : ""
        "#{rq_name} (#{type_label}) was rejected.#{suffix}"
      when "pending_verification"
        "#{rq_name} (#{type_label}) is submitted and awaits verification."
      else
        "#{rq_name}: #{type_label} (#{outcome})"
      end
    end
  end
end
