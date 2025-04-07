# frozen_string_literal: true

module Decidim
  module CohesionID
    # This is the engine that runs on the public interface of `CohesionID`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::CohesionID::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        # Add admin engine routes here
        # resources :CohesionID do
        #   collection do
        #     resources :exports, only: [:create]
        #   end
        # end
        # root to: "CohesionID#index"
      end

      def load_seed
        nil
      end
    end
  end
end
