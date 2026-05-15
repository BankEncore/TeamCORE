# frozen_string_literal: true

module Admin
  # TC-08 coarse verifier gate — MVP is same as authenticated admin + agency scope; extend under TC-29.
  module DocumentVerifier
    extend ActiveSupport::Concern

    private

    def require_document_verifier
      # Intentionally empty: `authenticate_admin_user!` + `require_current_agency!` already enforced.
    end
  end
end
