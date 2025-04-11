# frozen_string_literal: true

require 'deface'
require 'omniauth/strategies/cohesion_id'

require "decidim/cohesion_id/admin"
require "decidim/cohesion_id/engine"
require "decidim/cohesion_id/admin_engine"
require "decidim/cohesion_id/component"

require "decidim/cohesion_id/authentication"
require "decidim/cohesion_id/verification"

# require "decidim/cohesion_id/request"
# require "decidim/cohesion_id/response"
# require "decidim/cohesion_id/validation_error"


module Decidim
  # This namespace holds the logic of the `CohesionId` component. This component
  # allows users to create CohesionId in a participatory space.
  module CohesionId
    autoload :Tenant, "decidim/cohesion_id/tenant"

    class << self
      def tenants
        @tenants ||= []
      end

      def test!
        @test = true
      end

      def configure(&block)
        tenant = Decidim::CohesionId::Tenant.new(&block)
        tenants.each do |existing|
          if tenant.name == existing.name
            raise(
              TenantSameName,
              "Definisci il nome del Tenant. Il nome \"#{tenant.name}\" è già in uso."
            )
          end

          match = tenant.name =~ /^#{existing.name}/
          match ||= existing.name =~ /^#{tenant.name}/
          next unless match

        end

        tenants << tenant
      end

      def setup!
        raise "Il modulo CohesionId è già stato inizializzato!" if initialized?

        @initialized = true
        tenants.each(&:setup!)
      end

      def find_tenant(name)
        Decidim::CohesionId.tenants.select { |a| a.name == name}.try(:first)
      end

      private

      def initialized?
        @initialized
      end
    end

    class TenantSameName < StandardError; end

    class InvalidTenantName < StandardError; end
  end
end
