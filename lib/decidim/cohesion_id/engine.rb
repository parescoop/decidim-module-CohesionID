# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module CohesionId
    # This is the engine that runs on the public interface of CohesionId.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::CohesionId

      routes do
        # Add engine routes here
        # resources :CohesionId
        # root to: "CohesionId#index"
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
