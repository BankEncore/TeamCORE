# frozen_string_literal: true

module Payroll
  class PayPeriodGenerationService
    class Error < StandardError; end

    def self.call(agency:, actor:, configuration: nil, horizon_months_ahead: 24, horizon_months_back: 36)
      new(
        agency:,
        actor:,
        configuration:,
        horizon_months_ahead:,
        horizon_months_back:
      ).call
    end

    def initialize(agency:, actor:, configuration:, horizon_months_ahead:, horizon_months_back:)
      @agency = agency
      @actor = actor
      @configuration = configuration || agency.agency_payroll_configuration
      @horizon_months_ahead = horizon_months_ahead
      @horizon_months_back = horizon_months_back
    end

    def call
      raise Error, "Agency payroll configuration is missing." if configuration.blank?
      unless Access.can_generate_pay_periods?(user: actor, agency:)
        raise Error, "Not permitted to generate pay periods for this agency."
      end

      created = 0
      periods_in_range.each do |start_on, end_on|
        record = PayPeriod.find_or_initialize_by(agency_id: agency.id, start_on:, end_on:)
        next unless record.new_record?

        record.assign_attributes(
          status: "open",
          payroll_frequency: configuration.payroll_frequency,
          label: default_label(start_on, end_on)
        )
        record.save!
        created += 1
      end

      { created:, ensured_total: periods_in_range.size }
    end

    private

    attr_reader :agency, :actor, :configuration, :horizon_months_ahead, :horizon_months_back

    def range_start
      Date.current - horizon_months_back.months
    end

    def range_end
      Date.current + horizon_months_ahead.months
    end

    def periods_in_range
      case configuration.payroll_frequency
      when "weekly"
        stepping_ranges(configuration.pay_schedule_anchor_on, 7, ->(d) { d + 6.days })
      when "biweekly"
        stepping_ranges(configuration.pay_schedule_anchor_on, 14, ->(d) { d + 13.days })
      when "monthly"
        monthly_ranges
      when "semimonthly"
        semimonthly_ranges
      else
        raise Error, "Unsupported payroll frequency #{configuration.payroll_frequency.inspect}"
      end
    end

    def stepping_ranges(anchor, step_days, end_fn)
      raise Error, "pay_schedule_anchor_on is required for #{configuration.payroll_frequency}" if anchor.blank?

      ranges = []
      d = align_step_start(anchor, step_days)
      while d <= range_end
        end_on = end_fn.call(d)
        ranges << [ d, end_on ] if ranges_overlap_window?(d, end_on)
        d += step_days
      end
      ranges
    end

    def align_step_start(anchor, step_days)
      d = anchor
      while d > range_start
        d -= step_days
      end
      while d < range_start
        d += step_days
      end
      d
    end

    def monthly_ranges
      anchor = configuration.pay_schedule_anchor_on
      raise Error, "pay_schedule_anchor_on is required for monthly payroll" if anchor.blank?

      ranges = []
      m = [ anchor.beginning_of_month, range_start.beginning_of_month ].max
      while m <= range_end
        start_on = m
        end_on = m.end_of_month
        ranges << [ start_on, end_on ] if ranges_overlap_window?(start_on, end_on)
        m = m.next_month.beginning_of_month
      end
      ranges
    end

    def semimonthly_ranges
      ranges = []
      m = range_start.beginning_of_month
      while m <= range_end
        y, mo = m.year, m.month
        first_start = Date.new(y, mo, 1)
        first_end = Date.new(y, mo, 15)
        second_start = Date.new(y, mo, 16)
        second_end = Date.new(y, mo, -1)

        ranges << [ first_start, first_end ] if ranges_overlap_window?(first_start, first_end)
        ranges << [ second_start, second_end ] if ranges_overlap_window?(second_start, second_end)

        m = m.next_month.beginning_of_month
      end
      ranges
    end

    def ranges_overlap_window?(start_on, end_on)
      start_on <= range_end && end_on >= range_start
    end

    def default_label(start_on, end_on)
      "#{start_on.strftime('%b %d')} – #{end_on.strftime('%b %d, %Y')}"
    end
  end
end
