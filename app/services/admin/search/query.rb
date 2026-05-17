# frozen_string_literal: true

module Admin
  module Search
    class Query
      LIMIT = 12

      def initialize(agency:, q:)
        @agency = agency
        @raw = q.to_s.strip
      end

      def parties
        return [] if too_short?

        like = "%#{ActiveRecord::Base.sanitize_sql_like(@raw)}%"
        rows =
          Party
            .where(agency_id: @agency.id)
            .where("display_name LIKE ?", like)
            .order(:id)
            .limit(80)
            .to_a
        rows.sort_by { |p| [ text_rank(p.display_name), p.display_name.to_s.downcase, p.id ] }.first(LIMIT)
      end

      def team_members
        return [] if too_short?

        like = "%#{ActiveRecord::Base.sanitize_sql_like(@raw)}%"
        base = TeamMember.where(agency_id: @agency.id).joins(:party)
        rows =
          if @raw.match?(/\A\d+\z/)
            idv = @raw.to_i
            base.where(
              "team_members.id = ? OR parties.display_name LIKE ? OR team_members.team_member_number LIKE ?",
              idv,
              like,
              like
            )
          else
            base.where(
              "parties.display_name LIKE ? OR team_members.team_member_number LIKE ?",
              like,
              like
            )
          end
        rows = rows.includes(:party).distinct.limit(80).to_a
        rows.sort_by { |tm| [ text_rank(tm.party.display_name), tm.party.display_name.to_s.downcase, tm.id ] }.first(LIMIT)
      end

      def engagements
        return [] if too_short?

        like = "%#{ActiveRecord::Base.sanitize_sql_like(@raw)}%"
        by_title = Engagement.where(agency_id: @agency.id).where("engagements.title LIKE ?", like)
        by_party = Engagement.where(agency_id: @agency.id).joins(team_member: :party).where("parties.display_name LIKE ?", like)
        rows = (by_title.to_a + by_party.to_a).uniq(&:id)
        if @raw.match?(/\A\d+\z/)
          eid = @raw.to_i
          if eid.positive?
            extra = Engagement.where(agency_id: @agency.id, id: eid).includes(team_member: :party).to_a
            rows = (rows + extra).uniq(&:id)
          end
        end
        rows = Engagement.where(agency_id: @agency.id, id: rows.map(&:id)).includes(team_member: :party).limit(80).to_a
        rows.sort_by { |e| [ engagement_rank(e), e.title.to_s.downcase, e.id ] }.first(LIMIT)
      end

      private

      def too_short?
        @raw.length < 2
      end

      def text_rank(str)
        n = str.to_s.downcase
        lq = @raw.downcase
        return 0 if n == lq
        return 1 if n.start_with?(lq)

        2
      end

      def engagement_rank(eng)
        t = eng.title.to_s.downcase
        lq = @raw.downcase
        return 0 if eng.id.to_s == @raw
        return 1 if t == lq
        return 2 if t.start_with?(lq)

        3
      end
    end
  end
end
