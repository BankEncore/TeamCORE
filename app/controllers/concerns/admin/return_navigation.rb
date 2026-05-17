# frozen_string_literal: true

module Admin
  # Safe post-save redirects and form round-tripping for admin flows.
  # See docs/product/ux-design-guide.md (Admin return navigation contract).
  module ReturnNavigation
    extend ActiveSupport::Concern

    private

    # Returns a path+query string starting with /admin, same host only, or nil if unsafe/invalid.
    # Query strings are allowed on admin paths. Invalid values are ignored (callers use fallback).
    def safe_admin_return_path(raw)
      str = raw.to_s.strip
      return nil if str.blank?

      begin
        uri = URI.parse(str)
      rescue URI::InvalidURIError
        return nil
      end

      if uri.scheme.present?
        return nil unless %w[http https].include?(uri.scheme.downcase)
        return nil unless uri.host == request.host

        path = uri.path.to_s
        query_part = uri.query.present? ? "?#{uri.query}" : ""
      else
        # Protocol-relative URLs parse with a host (e.g. //evil.example/path)
        return nil if uri.host.present?

        path = uri.path.to_s
        path = "/#{path}" unless path.start_with?("/")
        query_part = uri.query.present? ? "?#{uri.query}" : ""
      end

      return nil if path.include?("..")
      return nil unless path == "/admin" || path.start_with?("/admin/")

      "#{path}#{query_part}"
    end

    def admin_return_redirect_target
      safe_admin_return_path(params[:team360_return_to]).presence ||
        safe_admin_return_path(params[:return_to]).presence
    end

    def redirect_after_admin_save(fallback_url, **redirect_options)
      url = admin_return_redirect_target || fallback_url
      redirect_to url, **redirect_options
    end
  end
end
