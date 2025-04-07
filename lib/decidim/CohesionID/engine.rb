# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module CohesionID
    # This is the engine that runs on the public interface of CohesionID.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::CohesionID

      routes do
        # Add engine routes here
        # resources :CohesionID
        # root to: "CohesionID#index"
      end

      initializer "CohesionID.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end
