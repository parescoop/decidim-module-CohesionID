module Decidim
  module CohesionId
    class OmniauthCohesionIdRegistrationForm < ::Decidim::OmniauthRegistrationForm

      attribute :invitation_token, String
      attribute :newsletter, Boolean

      validates :nickname, presence: true

      def normalized_nickname
        UserBaseEntity.nicknamize(nickname || name, organization: current_organization)
      end

      def raw_data
        data = super
        data.is_a?(Hash) ? data.to_json : data
      end

    end
  end
end