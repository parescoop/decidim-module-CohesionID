require_dependency Decidim::Admin::Engine.root.join('app', 'controllers', 'decidim', 'admin', 'officializations_controller').to_s

module Decidim
  module Admin
    class OfficializationsController < Decidim::Admin::ApplicationController
      include Decidim::Admin::Officializations::FilterableCohesionIdOverrides

      def translated_identities_provider_eq(id)
        I18n.t("decidim.authorization_handlers.#{id}_identity.name")
      end
    end
  end
end
