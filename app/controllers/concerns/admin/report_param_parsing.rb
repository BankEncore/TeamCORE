# frozen_string_literal: true

module Admin
  module ReportParamParsing
    extend ActiveSupport::Concern

    private

    def parse_report_date(value)
      return if value.blank?

      Date.iso8601(value.to_s)
    rescue ArgumentError
      nil
    end

    def parse_non_negative_int_param(value)
      return if value.blank?
      return unless value.to_s.match?(/\A\d+\z/)

      value.to_i
    end
  end
end
