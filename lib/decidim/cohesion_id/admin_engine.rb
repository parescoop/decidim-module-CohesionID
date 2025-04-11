# frozen_string_literal: true

module Decidim
  module CohesionId
    # This is the engine that runs on the public interface of `CohesionId`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::CohesionId::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        # Add admin engine routes here
        # resources :CohesionId do
        #   collection do
        #     resources :exports, only: [:create]
        #   end
        # end
        # root to: "CohesionId#index"
      end

      def load_seed
        nil
      end
    end
  end
end
