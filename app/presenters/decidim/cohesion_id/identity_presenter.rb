# frozen_string_literal: true

module Decidim
  module CohesionId
    class IdentityPresenter < Decidim::Log::ResourcePresenter
      private

      def present_resource_name
        resource && resource.provider && I18n.exists?("decidim.authorization_handlers.#{resource.provider}_identity.name") ?
          I18n.t("decidim.authorization_handlers.#{resource.provider}_identity.name") :'CohesionID'
      end

    end
  end
end