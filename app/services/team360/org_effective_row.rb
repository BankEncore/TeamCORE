# frozen_string_literal: true

module Team360
  # Effective-dating helper for placements and supervision (as-of Team360 / reports).
  module OrgEffectiveRow
    module_function

    def pick(rows, as_of_date)
      return if rows.blank?

      candidates =
        rows.select do |r|
          r.effective_start_on <= as_of_date &&
            (r.effective_end_on.nil? || r.effective_end_on >= as_of_date)
        end
      return if candidates.empty?

      candidates.max_by(&:effective_start_on)
    end
  end
end
