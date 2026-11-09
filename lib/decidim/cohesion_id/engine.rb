# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module CohesionId
    # This is the engine that runs on the public interface of CohesionId.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::CohesionId

      routes do
        devise_scope :user do
          match(
            "/users/sign_out",
            to: "sessions#destroy",
            as: "destroy_user_session",
            via: [:delete, :post]
          )
        end
      end

      initializer "decidim_cohesion_id.mount_routes", before: :add_routing_paths do
        Decidim::Core::Engine.routes.prepend do
          mount Decidim::CohesionId::Engine => "/"
        end
      end

      initializer "decidim_cohesion_id.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end

      initializer "decidim_cohesion_id.setup", before: "devise.omniauth" do
        Decidim::CohesionId.setup!
      end

      initializer "decidim_cohesion_id.session.same_site_none", before: "decidim_core.session_store" do
        Rails.application.config.action_dispatch.cookies_same_site_protection = :none
        Decidim.config.force_ssl = ENV["APP_SCHEME"] == "https" || !Rails.env.development?
      end

      rake_tasks do
        Dir.glob(File.expand_path("../../tasks/**/*.rake", __dir__)).each { |f| load f }
      end

      overrides = "#{Decidim::CohesionId::Engine.root}/app/overrides"
      config.to_prepare do
        Rails.autoloaders.main.ignore(overrides)
        Dir.glob("#{overrides}/**/*_override.rb").each do |override|
          load override
        end
      end
    end
  end
end
