module Decidim
  module Admin
    module Officializations
      module FilterableCohesionIdOverrides

        extend ActiveSupport::Concern

        included do
          include Decidim::Admin::Filterable

          private

          def base_query
            c = collection
            identity_filter = ransack_params[:identities_provider_eq]
            unless identity_filter.nil?
              c = identity_filter.present? ? c.where(id: provider_ids) : c.where.not(id: provider_ids)
            end

            c.distinct
          end

          def filters_with_values
            {
              officialized_at_null: ['true', 'false'],
              identities_provider_eq: Decidim::Identity.all.map(&:provider).uniq + [nil]
            }
          end

          def dynamically_translated_filters
            [:scope_id_eq, :category_id_eq, :identities_provider_eq]
          end

          def provider_ids
            f = ransack_params[:identities_provider_eq]
            (f.blank? ? Decidim::Identity.all : Decidim::Identity.where(provider: f))&.pluck(:decidim_user_id)
          end

          def filters
            [:officialized_at_null, :identities_provider_eq]
          end

        end
      end
    end
  end
end