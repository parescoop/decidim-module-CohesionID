# frozen_string_literal: true

module Decidim
  module CohesionId
    module Verification
      class MetadataCollector
        def initialize(tenant, attributes)
          @tenant = tenant
          @attributes = attributes
        end

        def metadata
          return nil unless tenant.metadata_attributes.is_a?(Hash)
          return nil if tenant.metadata_attributes.blank?

          collect.delete_if { |_k, v| v.nil? }
        end

        protected

        attr_reader :tenant, :attributes

        def collect
          return {} if attributes.blank?
          tenant.metadata_attributes.map do |key, defs|
            value = begin
                      case defs
                      when Hash
                        attributes.public_send(defs[:type], defs[:name])
                      when String
                        attributes.dig(defs.to_sym)
                      when Array
                        attributes.values_at(*defs.map(&:to_sym)).try(:compact).try(:first)
                      end
                    end

            [key, value]
          end.to_h
        end
      end
    end
  end
end