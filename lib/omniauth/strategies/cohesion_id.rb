require "decidim/cohesion_id/request"
require "decidim/cohesion_id/response"
require "decidim/cohesion_id/client"
require "decidim/cohesion_id/validation_error"
require "cgi"
require "openssl"
require "securerandom"

module OmniAuth
  module Strategies
    class CohesionId

      include OmniAuth::Strategy

      option :uid_attribute, :codice_fiscale

      def request_phase
        state = signed_state

        request = Decidim::CohesionId::Request.new(options.settings)
        redirect request.create(callback_url_with_state(state))
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
        validate_state!

        response = Decidim::CohesionId::Response.new(options.settings, request.params["auth"])
        if response.valid?(expected_url: callback_url) && parse_data(response.get_data)
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

      private

      def callback_url_with_state(state)
        separator = callback_url.include?("?") ? "&" : "?"
        "#{callback_url}#{separator}state=#{CGI.escape(state)}"
      end

      def signed_state
        nonce = SecureRandom.hex(32)
        issued_at = Time.current.to_i
        data = [nonce, issued_at, options.name.to_s].join(":")
        signature = sign_state_data(data)
        "#{data}--#{signature}"
      end

      def validate_state!
        provided_state = request.params["state"].to_s
        raise Decidim::CohesionId::ValidationError.new("Invalid callback state") if provided_state.blank?

        data, signature = provided_state.split("--", 2)
        raise Decidim::CohesionId::ValidationError.new("Invalid callback state") if data.blank? || signature.blank?
        raise Decidim::CohesionId::ValidationError.new("Invalid callback state") unless ActiveSupport::SecurityUtils.secure_compare(sign_state_data(data), signature)

        nonce, issued_at, provider = data.split(":", 3)

        state_ttl = 10.minutes.to_i
        raise Decidim::CohesionId::ValidationError.new("Invalid callback state") if nonce.blank? || provider != options.name.to_s
        raise Decidim::CohesionId::ValidationError.new("Expired callback state") if issued_at.to_i.zero? || (Time.current.to_i - issued_at.to_i) > state_ttl

        replay_key = "decidim-#{options.name}.used_state.#{nonce}"
        accepted = Rails.cache.write(replay_key, true, unless_exist: true, expires_in: state_ttl)
        raise Decidim::CohesionId::ValidationError.new("Replay callback state") unless accepted
      end

      def sign_state_data(data)
        OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base.to_s, data)
      end

    end
  end
end
