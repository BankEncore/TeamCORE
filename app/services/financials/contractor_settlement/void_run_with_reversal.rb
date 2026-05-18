# frozen_string_literal: true

module Financials
  module ContractorSettlement
    class VoidRunWithReversal
      class Error < StandardError; end

      VOIDABLE_STATUSES = %w[draft calculated finalized].freeze
      REVERSIBLE_CHARGE_STATUSES = %w[open closed].freeze

      def self.call(run:, actor:, reason:)
        new(run:, actor:, reason:).call
      end

      def initialize(run:, actor:, reason:)
        @run = run
        @actor = actor
        @reason = reason.to_s.strip
      end

      def call
        raise Error, "Reason is required." if @reason.blank?
        raise Error, "Run is already voided." if @run.status == "voided"
        raise Error, "Run cannot be voided from #{@run.status}." unless @run.status.in?(VOIDABLE_STATUSES)
        raise Error, "Paid settlement runs cannot be voided." if @run.status == "paid_recorded"
        raise Error, "Settlement runs with exports cannot be voided." if @run.contractor_settlement_exports.exists?

        @run.with_lock do
          @run.reload
          raise Error, "Run is already voided." if @run.status == "voided"
          raise Error, "Run cannot be voided from #{@run.status}." unless @run.status.in?(VOIDABLE_STATUSES)
          raise Error, "Settlement runs with exports cannot be voided." if @run.contractor_settlement_exports.exists?

          ContractorSettlementRun.transaction do
            @run.contractor_settlement_lines
              .includes(contractor_charge_recoveries: :contractor_charge)
              .find_each do |line|
                reverse_settlement_deductions_for_line!(line)
              end

            @run.update!(status: "voided")
            ContractorSettlementRunEvent.create!(
              contractor_settlement_run: @run,
              event_type: "voided",
              actor: @actor,
              reason: @reason
            )
          end
        end

        @run
      end

      private

      def reverse_settlement_deductions_for_line!(line)
        line.contractor_charge_recoveries
          .where(source_type: "settlement_deduction")
          .find_each do |recovery|
            next if reversal_exists_for?(line, recovery)

            reverse_deduction!(line:, recovery:)
          end
      end

      def reversal_exists_for?(line, recovery)
        line.contractor_charge_recoveries
          .where(source_type: "settlement_deduction_reversal")
          .where("notes LIKE ?", "%original recovery ##{recovery.id}%")
          .exists?
      end

      def reverse_deduction!(line:, recovery:)
        charge = ContractorCharge.lock.find_by!(id: recovery.contractor_charge_id, agency_id: @run.agency_id)
        validate_charge_status!(charge)

        new_balance = charge.open_balance_cents + recovery.amount_cents
        if charge.original_amount_cents && new_balance > charge.original_amount_cents
          new_balance = charge.original_amount_cents
        end

        charge.update!(
          open_balance_cents: new_balance,
          status: restored_charge_status(charge, new_balance)
        )

        ContractorChargeRecovery.create!(
          agency_id: @run.agency_id,
          contractor_charge: charge,
          contractor_settlement_line: line,
          source_type: "settlement_deduction_reversal",
          amount_cents: recovery.amount_cents,
          occurred_on: Date.current,
          actor_id: @actor&.id,
          notes: reversal_notes(recovery)
        )
      end

      def validate_charge_status!(charge)
        return if charge.status.in?(REVERSIBLE_CHARGE_STATUSES)

        if charge.status.in?(%w[waived cancelled])
          raise Error,
            "Charge ##{charge.id} is #{charge.status}; void cannot reverse settlement deductions after waiver or cancellation."
        end

        raise Error,
          "Charge ##{charge.id} is #{charge.status}; settlement deductions should only apply to open or closed charges."
      end

      def restored_charge_status(charge, new_balance_cents)
        return charge.status unless charge.status == "closed"

        new_balance_cents.positive? ? "open" : "closed"
      end

      def reversal_notes(recovery)
        "Reversal for voided settlement run ##{@run.id} (original recovery ##{recovery.id}). #{@reason}"
      end
    end
  end
end
