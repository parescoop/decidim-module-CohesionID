require "decidim/cohesion_id/request"
require "decidim/cohesion_id/response"
require "decidim/cohesion_id/client"
require "decidim/cohesion_id/validation_error"

module OmniAuth
  module Strategies
    class CohesionId

      include OmniAuth::Strategy

      option :uid_attribute, :codice_fiscale

      def request_phase
        request = Decidim::CohesionId::Request.new(options.settings)
        redirect request.create(callback_url)
      end

      uid do
        if options.uid_attribute
          ret =  @attributes.dig(options.uid_attribute)
          if ret.nil?
            raise OmniAuth::Strategies::SAML::ValidationError.new("SAML response missing '#{options.uid_attribute}' attribute")
          end
          ret
        else
          @name_id
        end
      end

      info do
        @attributes
      end

      def callback_phase
        raise Decidim::CohesionId::ValidationError.new("XML response missing") unless request.params["auth"]

        response = Decidim::CohesionId::Response.new(options.settings, request.params["auth"])
        if response.valid? && parse_data(response.get_data)
          env['omniauth.auth'] = auth_hash
          call_app!
        else
          raise Decidim::CohesionId::ValidationError.new(response.errors.try(:first))
        end
        # end
      rescue Decidim::CohesionId::ValidationError
        fail!(:invalid_ticket, $!)
      end

      def parse_data(data)
        @name_id = data.dig(:codice_fiscale)
        session["decidim-#{options.name}.id_sessione_sso"] = data.dig(:id_sessione_sso)
        session["decidim-#{options.name}.id_sessione_aspnet_sso"] = data.dig(:id_sessione_aspnet_sso)
        @attributes = data
      rescue Exception => ex
        raise Decidim::CohesionId::ValidationError.new(ex)
      end

    end
  end
end
