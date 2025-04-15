module Decidim
  module Admin
    module Officializations
      module FilterableCohesionIdOverrides

        extend ActiveSupport::Concern

        included do
          include Decidim::Admin::Filterable

          private

          def filters_with_values
            {
              officialized_at_null: ['true', 'false'],
              identities_provider_eq: Decidim::Identity.all.map(&:provider).uniq + [nil]
            }
          end

          def dynamically_translated_filters
            [:scope_id_eq, :category_id_eq, :identities_provider_eq]
          end

        end
      end
    end
  end
end