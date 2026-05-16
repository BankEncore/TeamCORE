# frozen_string_literal: true

module Admin
  module Reports
    class BaseController < Admin::BaseController
      include Admin::ReportParamParsing
    end
  end
end
