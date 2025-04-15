# frozen_string_literal: true

module Decidim
  module CohesionId
    # This is the engine that runs on the public interface of `CohesionId`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::CohesionId::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      initializer "decidim_cohesion_id_admin.mount_routes", before: "decidim_admin.mount_routes" do
        Decidim::Admin::Engine.routes.append do
          mount Decidim::CohesionId::AdminEngine => "/"
        end
      end

      initializer "decidim_cohesion:ud.view_helpers" do
        ActiveSupport.on_load(:action_controller_base) do
          helper Decidim::CohesionId::Admin::ApplicationHelper
        end
      end

      def load_seed
        nil
      end
    end
  end
end
